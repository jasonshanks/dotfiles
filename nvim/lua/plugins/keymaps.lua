-- ⌨️ Keymaps: pickers, git helpers and buffer-local LSP actions.

local map = vim.keymap.set
local Snacks = require("snacks")

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
local function root_dir()
  local markers = {
    ".git",
    "lua",
    "package.json",
    "Makefile",
    ".luarc.json",
    ".luacheckrc",
    "stylua.toml",
    "go.mod",
    "Cargo.toml",
    "composer.json",
    "pyproject.toml",
  }
  return vim.fs.root(vim.api.nvim_get_current_buf(), markers) or vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
end

---Pick from the project root (or the cwd when `opts.root == false`).
---@param source string
---@param opts? table
local function pick(source, opts)
  opts = vim.deepcopy(opts or {})
  local use_root = opts.root ~= false
  opts.root = nil
  return function()
    local o = vim.deepcopy(opts)
    if use_root then
      o.cwd = root_dir()
    end
    Snacks.picker.pick(source, o)
  end
end

local function config_files()
  return function()
    Snacks.picker.pick("files", {
      cwd = vim.fs.normalize(vim.fn.stdpath("config")),
      title = "Config Files",
    })
  end
end

-- Oil: File explorer
map("n", "-", function()
  require("oil").open_float(nil, { preview = {} })
end, { desc = "Open Oil" })

--------------------------------------------------------------------------------
-- Snacks picker
--------------------------------------------------------------------------------
map("n", "<leader>,", function()
  Snacks.picker.buffers()
end, { desc = "Buffers" })
map("n", "<leader>/", pick("grep"), { desc = "Grep (Root Dir)" })
map("n", "<leader>:", function()
  Snacks.picker.command_history()
end, { desc = "Command History" })
map("n", "<leader><space>", pick("files"), { desc = "Find Files (Root Dir)" })
map("n", "<leader>n", function()
  Snacks.picker.notifications()
end, { desc = "Notification History" })

-- find
map("n", "<leader>fb", function()
  Snacks.picker.buffers()
end, { desc = "Buffers" })
map("n", "<leader>fB", function()
  Snacks.picker.buffers({ hidden = true, nofile = true })
end, { desc = "Buffers (all)" })
map("n", "<leader>fc", config_files(), { desc = "Find Config File" })
map("n", "<leader>ff", pick("files"), { desc = "Find Files (Root Dir)" })
map("n", "<leader>fF", pick("files", { root = false }), { desc = "Find Files (cwd)" })
map("n", "<leader>fg", function()
  Snacks.picker.git_files()
end, { desc = "Find Files (git-files)" })
map("n", "<leader>fr", pick("recent"), { desc = "Recent" })
map("n", "<leader>fR", function()
  Snacks.picker.recent({ filter = { cwd = true } })
end, { desc = "Recent (cwd)" })
map("n", "<leader>fp", function()
  Snacks.picker.projects()
end, { desc = "Projects" })
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- git
map("n", "<leader>gd", function()
  Snacks.picker.git_diff()
end, { desc = "Git Diff (hunks)" })
map("n", "<leader>gD", function()
  Snacks.picker.git_diff({ base = "origin", group = true })
end, { desc = "Git Diff (origin)" })
map("n", "<leader>gs", function()
  Snacks.picker.git_status()
end, { desc = "Git Status" })
map("n", "<leader>gS", function()
  Snacks.picker.git_stash()
end, { desc = "Git Stash" })
map("n", "<leader>gi", function()
  Snacks.picker.gh_issue()
end, { desc = "GitHub Issues (open)" })
map("n", "<leader>gI", function()
  Snacks.picker.gh_issue({ state = "all" })
end, { desc = "GitHub Issues (all)" })
map("n", "<leader>gp", function()
  Snacks.picker.gh_pr()
end, { desc = "GitHub Pull Requests (open)" })
map("n", "<leader>gP", function()
  Snacks.picker.gh_pr({ state = "all" })
end, { desc = "GitHub Pull Requests (all)" })

-- lazygit
if vim.fn.executable("lazygit") == 1 then
  map("n", "<leader>gg", function()
    Snacks.lazygit({ cwd = root_dir() })
  end, { desc = "Lazygit (Root Dir)" })
  map("n", "<leader>gG", function()
    Snacks.lazygit()
  end, { desc = "Lazygit (cwd)" })
end

map("n", "<leader>gl", function()
  Snacks.picker.git_log({ cwd = root_dir() })
end, { desc = "Git Log" })
map("n", "<leader>gL", function()
  Snacks.picker.git_log()
end, { desc = "Git Log (cwd)" })
-- LazyVim names this "Git Blame Line" but it opens the line's commit history.
-- The full `git blame` for the current line is `<leader>ghb` (Gitsigns).
map("n", "<leader>gb", function()
  Snacks.picker.git_log_line()
end, { desc = "Git Log Line (line history; see <leader>ghb for blame)" })
map("n", "<leader>gf", function()
  Snacks.picker.git_log_file()
end, { desc = "Git Current File History" })
map({ "n", "x" }, "<leader>gB", function()
  Snacks.gitbrowse()
end, { desc = "Git Browse (open)" })
map({ "n", "x" }, "<leader>gY", function()
  Snacks.gitbrowse({
    open = function(url)
      vim.fn.setreg("+", url)
    end,
    notify = false,
  })
end, { desc = "Git Browse (copy)" })

-- buffers
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })
map("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, { desc = "Delete Other Buffers" })
map("n", "<leader>bi", function()
  Snacks.bufdelete.invisible()
end, { desc = "Delete Invisible Buffers" })
map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })
map("n", "<leader>bj", function()
  Snacks.picker.buffers()
end, { desc = "Pick Buffer" })

-- grep
map("n", "<leader>sb", function()
  Snacks.picker.lines()
end, { desc = "Buffer Lines" })
map("n", "<leader>sB", function()
  Snacks.picker.grep_buffers()
end, { desc = "Grep Open Buffers" })
map("n", "<leader>sg", pick("grep"), { desc = "Grep (Root Dir)" })
map("n", "<leader>sG", pick("grep", { root = false }), { desc = "Grep (cwd)" })
map({ "n", "x" }, "<leader>sw", pick("grep_word"), { desc = "Visual selection or word (Root Dir)" })
map({ "n", "x" }, "<leader>sW", pick("grep_word", { root = false }), { desc = "Visual selection or word (cwd)" })

-- search
map("n", '<leader>s"', function()
  Snacks.picker.registers()
end, { desc = "Registers" })
map("n", "<leader>s/", function()
  Snacks.picker.search_history()
end, { desc = "Search History" })
map("n", "<leader>sa", function()
  Snacks.picker.autocmds()
end, { desc = "Autocmds" })
map("n", "<leader>sc", function()
  Snacks.picker.command_history()
end, { desc = "Command History" })
map("n", "<leader>sC", function()
  Snacks.picker.commands()
end, { desc = "Commands" })
map("n", "<leader>sd", function()
  Snacks.picker.diagnostics()
end, { desc = "Diagnostics" })
map("n", "<leader>sD", function()
  Snacks.picker.diagnostics_buffer()
end, { desc = "Buffer Diagnostics" })
map("n", "<leader>sh", function()
  Snacks.picker.help()
end, { desc = "Help Pages" })
map("n", "<leader>sH", function()
  Snacks.picker.highlights()
end, { desc = "Highlights" })
map("n", "<leader>si", function()
  Snacks.picker.icons()
end, { desc = "Icons" })
map("n", "<leader>sj", function()
  Snacks.picker.jumps()
end, { desc = "Jumps" })
map("n", "<leader>sk", function()
  Snacks.picker.keymaps()
end, { desc = "Keymaps" })
map("n", "<leader>sl", function()
  Snacks.picker.loclist()
end, { desc = "Location List" })
map("n", "<leader>sM", function()
  Snacks.picker.man()
end, { desc = "Man Pages" })
map("n", "<leader>sm", function()
  Snacks.picker.marks()
end, { desc = "Marks" })
map("n", "<leader>sR", function()
  Snacks.picker.resume()
end, { desc = "Resume" })
map("n", "<leader>sq", function()
  Snacks.picker.qflist()
end, { desc = "Quickfix List" })
map("n", "<leader>su", function()
  Snacks.picker.undo()
end, { desc = "Undotree" })

-- ui
map("n", "<leader>uC", function()
  Snacks.picker.colorschemes()
end, { desc = "Colorschemes" })
map("n", "<leader>un", function()
  Snacks.notifier.hide()
end, { desc = "Dismiss All Notifications" })

-- toggles
Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
Snacks.toggle.diagnostics():map("<leader>ud")
Snacks.toggle.line_number():map("<leader>ul")
Snacks.toggle
  .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" })
  :map("<leader>uc")
Snacks.toggle.treesitter():map("<leader>uT")
Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
Snacks.toggle.dim():map("<leader>uD")
Snacks.toggle.indent():map("<leader>ug")
Snacks.toggle.scroll():map("<leader>uS")
Snacks.toggle.get("zoom"):map("wm")
Snacks.toggle.zoom():map("<leader>uZ")
Snacks.toggle.zen():map("<leader>uz")
Snacks.toggle({
  name = "Git Signs",
  get = function()
    return require("gitsigns.config").config.signcolumn
  end,
  set = function(state)
    require("gitsigns").toggle_signs(state)
  end,
}):map("<leader>uG")
if vim.lsp.inlay_hint then
  Snacks.toggle.inlay_hints():map("<leader>uh")
end
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
map("n", "<leader>uI", function()
  vim.treesitter.inspect_tree()
  vim.api.nvim_input("I")
end, { desc = "Inspect Tree" })

-- Active mini.animate extra overrides LazyVim's default Snacks toggle.
Snacks.toggle({
  name = "Mini Animate",
  get = function()
    return not vim.g.minianimate_disable
  end,
  set = function(state)
    vim.g.minianimate_disable = not state
  end,
}):map("<leader>ua")

-- floating terminal
map({ "n", "t" }, "<c-/>", function()
  Snacks.terminal.focus(nil, { cwd = root_dir() })
end, { desc = "Terminal (Root Dir)" })

-- CodeDiff
map("n", "<leader>gv", "<cmd>CodeDiff<cr>", { desc = "Toggle CodeDiff" })
-- File history
map("n", "<leader>gh", "<cmd>CodeDiff history %<cr>", { desc = "File history (current file)" })
map("n", "<leader>gH", "<cmd>CodeDiff history<cr>", { desc = "File history (repo)" })

-- diagnostics
local function diagnostic_goto(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
      end,
    })
  end
end

map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- location / quickfix lists
map("n", "<leader>xl", function()
  local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Location List" })
map("n", "<leader>xq", function()
  local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Quickfix List" })

-- format
map({ "n", "x" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format" })
-- lua: buffer-local `<localleader>r` (vim.keymap.set has no `ft` option; use FileType).
local lua_run_group = vim.api.nvim_create_augroup("LuaRunKeymap", { clear = true })

local function map_lua_run(buf)
  map({ "n", "x" }, "<localleader>r", function()
    Snacks.debug.run()
  end, { buffer = buf, desc = "Run Lua" })
end

vim.api.nvim_create_autocmd("FileType", {
  group = lua_run_group,
  pattern = "lua",
  callback = function(event)
    map_lua_run(event.buf)
  end,
})

for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "lua" then
    map_lua_run(buf)
  end
end

--------------------------------------------------------------------------------
-- Buffer-local LSP actions
--------------------------------------------------------------------------------
---@param bufnr integer
---@param methods string|string[]
local function supports(bufnr, methods)
  if type(methods) == "string" then
    methods = { methods }
  end
  for _, method in ipairs(methods) do
    local name = method:find("/") and method or ("textDocument/" .. method)
    if #vim.lsp.get_clients({ bufnr = bufnr, method = name }) > 0 then
      return true
    end
  end
  return false
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local bufnr = event.buf
    local function lmap(lhs, rhs, desc, methods, opts)
      opts = vim.tbl_extend("force", { buffer = bufnr, desc = desc, silent = true }, opts or {})
      local mode = opts.mode or "n"
      opts.mode = nil
      if methods and not supports(bufnr, methods) then
        return
      end
      map(mode, lhs, rhs, opts)
    end

    lmap("<leader>cl", function()
      Snacks.picker.lsp_config()
    end, "Lsp Info")

    lmap("gd", function()
      Snacks.picker.lsp_definitions()
    end, "Goto Definition", "definition")
    lmap("gr", function()
      Snacks.picker.lsp_references()
    end, "References")
    lmap("gI", function()
      Snacks.picker.lsp_implementations()
    end, "Goto Implementation", "implementation")
    lmap("gy", function()
      Snacks.picker.lsp_type_definitions()
    end, "Goto T[y]pe Definition", "typeDefinition")
    lmap("gD", vim.lsp.buf.declaration, "Goto Declaration", "declaration")
    lmap("K", vim.lsp.buf.hover, "Hover")
    lmap("gK", vim.lsp.buf.signature_help, "Signature Help", "signatureHelp")
    if supports(bufnr, "signatureHelp") then
      map("i", "<c-k>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Signature Help", silent = true })
    end

    lmap("<leader>ss", function()
      Snacks.picker.lsp_symbols()
    end, "LSP Symbols", "documentSymbol")
    lmap("<leader>sS", function()
      Snacks.picker.lsp_workspace_symbols()
    end, "LSP Workspace Symbols", "workspace/symbols")
    lmap("gai", function()
      Snacks.picker.lsp_incoming_calls()
    end, "C[a]lls Incoming", "callHierarchy/incomingCalls")
    lmap("gao", function()
      Snacks.picker.lsp_outgoing_calls()
    end, "C[a]lls Outgoing", "callHierarchy/outgoingCalls")

    lmap("<leader>ca", vim.lsp.buf.code_action, "Code Action", "codeAction", { mode = { "n", "x" } })
    lmap("<leader>cc", function()
      vim.lsp.codelens.run()
    end, "Run Codelens", "codeLens")
    lmap("<leader>cC", function()
      vim.lsp.codelens.refresh()
    end, "Refresh & Display Codelens", "codeLens")
    lmap("<leader>cR", function()
      Snacks.rename.rename_file()
    end, "Rename File", { "workspace/didRenameFiles", "workspace/willRenameFiles" })
    lmap("<leader>cr", vim.lsp.buf.rename, "Rename", "rename")
    lmap("<leader>cA", function()
      vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} }, apply = true })
    end, "Source Action", "codeAction")
    lmap("<leader>co", function()
      vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" }, diagnostics = {} }, apply = true })
    end, "Organize Imports", "codeAction")

    lmap("]]", function()
      Snacks.words.jump(vim.v.count1)
    end, "Next Reference", "documentHighlight")
    lmap("[[", function()
      Snacks.words.jump(-vim.v.count1)
    end, "Prev Reference", "documentHighlight")
    lmap("<a-n>", function()
      Snacks.words.jump(vim.v.count1, true)
    end, "Next Reference", "documentHighlight")
    lmap("<a-p>", function()
      Snacks.words.jump(-vim.v.count1, true)
    end, "Prev Reference", "documentHighlight")
  end,
})
