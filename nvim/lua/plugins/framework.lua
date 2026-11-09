-- 🧩 Framework: the LazyVim-provided plugins that were active in the previous
-- configuration, wired up with their own setup() instead of lazy.nvim.
--
-- Loaded after `plugins.lsp` so LSP integrations (rustaceanvim, crates, lazydev)
-- can extend the native `vim.lsp.config` setup before buffers attach.

local map = vim.keymap.set

-- Markdown / MDX filetype (LazyVim lang.markdown extra).
vim.filetype.add({
  extension = { mdx = "markdown.mdx" },
})

-- Treesitter helpers -------------------------------------------------------
local function ts_lang(ft)
  return vim.treesitter.language.get_lang(ft)
end

---True when the language has a parser and the given query for `ft`.
---@param ft string
---@param query string
---@return boolean
local function ts_have(ft, query)
  local lang = ts_lang(ft)
  if not lang or not pcall(vim.treesitter.language.add, lang) then
    return false
  end
  local ok, q = pcall(vim.treesitter.query.get, lang, query)
  return ok and q ~= nil
end

--------------------------------------------------------------------------------
-- ts-comments: better comment syntax (replaces mini.comment)
--------------------------------------------------------------------------------
require("ts-comments").setup({})

--------------------------------------------------------------------------------
-- mini.ai: extended a/i text objects (+ buffer, tree-sitter objects)
--------------------------------------------------------------------------------
-- Ported from LazyVim's `LazyVim.mini.ai_buffer`.
local function ai_buffer(ai_type)
  local start_line, end_line = 1, vim.fn.line("$")
  if ai_type == "i" then
    local first_nonblank, last_nonblank = vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
    if first_nonblank == 0 or last_nonblank == 0 then
      return { from = { line = start_line, col = 1 } }
    end
    start_line, end_line = first_nonblank, last_nonblank
  end

  local to_col = math.max(vim.fn.getline(end_line):len(), 1)
  return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
end

-- Ported from LazyVim's `LazyVim.mini.ai_whichkey`.
local function ai_whichkey(opts)
  local objects = {
    { " ", desc = "whitespace" },
    { '"', desc = '" string' },
    { "'", desc = "' string" },
    { "(", desc = "() block" },
    { ")", desc = "() block with ws" },
    { "<", desc = "<> block" },
    { ">", desc = "<> block with ws" },
    { "?", desc = "user prompt" },
    { "U", desc = "use/call without dot" },
    { "[", desc = "[] block" },
    { "]", desc = "[] block with ws" },
    { "_", desc = "underscore" },
    { "`", desc = "` string" },
    { "a", desc = "argument" },
    { "b", desc = ")]} block" },
    { "c", desc = "class" },
    { "d", desc = "digit(s)" },
    { "e", desc = "CamelCase / snake_case" },
    { "f", desc = "function" },
    { "g", desc = "entire file" },
    { "i", desc = "indent" },
    { "o", desc = "block, conditional, loop" },
    { "q", desc = "quote `\"'" },
    { "t", desc = "tag" },
    { "u", desc = "use/call" },
    { "{", desc = "{} block" },
    { "}", desc = "{} with ws" },
  }

  ---@type wk.Spec[]
  local ret = { mode = { "o", "x" } }
  local mappings = vim.tbl_extend("force", {}, {
    around = "a",
    inside = "i",
    around_next = "an",
    inside_next = "in",
    around_last = "al",
    inside_last = "il",
  }, opts.mappings or {})
  mappings.goto_left = nil
  mappings.goto_right = nil

  for name, prefix in pairs(mappings) do
    name = name:gsub("^around_", ""):gsub("^inside_", "")
    ret[#ret + 1] = { prefix, group = name }
    for _, obj in ipairs(objects) do
      local desc = obj.desc
      if prefix:sub(1, 1) == "i" then
        desc = desc:gsub(" with ws", "")
      end
      ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
    end
  end
  require("which-key").add(ret, { notify = false })
end

local mini_ai_opts = (function()
  local ai = require("mini.ai")
  return {
    n_lines = 500,
    custom_textobjects = {
      o = ai.gen_spec.treesitter({ -- code block
        a = { "@block.outer", "@conditional.outer", "@loop.outer" },
        i = { "@block.inner", "@conditional.inner", "@loop.inner" },
      }),
      f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
      c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
      t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
      d = { "%f[%d]%d+" }, -- digits
      e = { -- Word with case
        { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
        "^().*()$",
      },
      g = ai_buffer, -- buffer
      u = ai.gen_spec.function_call(), -- u for "Usage"
      U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
    },
  }
end)()

require("mini.ai").setup(mini_ai_opts)
vim.schedule(function()
  ai_whichkey(mini_ai_opts)
end)

--------------------------------------------------------------------------------
-- todo-comments: highlight and jump between TODO/FIX/NOTE/...
--------------------------------------------------------------------------------
require("todo-comments").setup({})

map("n", "]t", function()
  require("todo-comments").jump_next()
end, { desc = "Next Todo Comment" })
map("n", "[t", function()
  require("todo-comments").jump_prev()
end, { desc = "Previous Todo Comment" })

map("n", "<leader>st", "<cmd>Trouble todo toggle<cr>", { desc = "Todo" })
map("n", "<leader>sT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", { desc = "Todo/Fix/Fixme" })

--------------------------------------------------------------------------------
-- grug-far: search/replace across files
--------------------------------------------------------------------------------
require("grug-far").setup({ headerMaxWidth = 80 })

map({ "n", "x" }, "<leader>sr", function()
  local grug = require("grug-far")
  local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
  grug.open({
    transient = true,
    prefills = {
      filesFilter = ext and ext ~= "" and "*." .. ext or nil,
    },
  })
end, { desc = "Search and Replace" })

--------------------------------------------------------------------------------
-- persistence.nvim: session management (`<leader>q*`)
--------------------------------------------------------------------------------
require("persistence").setup({})

map("n", "<leader>qa", "<cmd>qa<cr>", { desc = "Quit all" })
map("n", "<leader>qs", function()
  require("persistence").load()
end, { desc = "Restore Session" })
map("n", "<leader>qS", function()
  require("persistence").select()
end, { desc = "Select Session" })
map("n", "<leader>ql", function()
  require("persistence").load({ last = true })
end, { desc = "Restore Last Session" })
map("n", "<leader>qd", function()
  require("persistence").stop()
end, { desc = "Don't Save Current Session" })

--------------------------------------------------------------------------------
-- neo-tree: file explorer (`<leader>e`, `<leader>fe`, `<leader>ge`, `<leader>be`)
--------------------------------------------------------------------------------
---Lazily resolve the directory so the map follows the current buffer/cwd.
---@param which "root"|"cwd"
local function neo_tree(which)
  return function()
    local dir = which == "root" and (vim.fs.root(0, ".git") or vim.uv.cwd()) or vim.uv.cwd()
    require("neo-tree.command").execute({ toggle = true, dir = dir })
  end
end

map("n", "<leader>fe", neo_tree("root"), { desc = "Explorer NeoTree (Root Dir)" })
map("n", "<leader>fE", neo_tree("cwd"), { desc = "Explorer NeoTree (cwd)" })
map("n", "<leader>e", "<leader>fe", { desc = "Explorer NeoTree (Root Dir)", remap = true })
map("n", "<leader>E", "<leader>fE", { desc = "Explorer NeoTree (cwd)", remap = true })
map("n", "<leader>ge", function()
  require("neo-tree.command").execute({ source = "git_status", toggle = true })
end, { desc = "Git Explorer" })
map("n", "<leader>be", function()
  require("neo-tree.command").execute({ source = "buffers", toggle = true })
end, { desc = "Buffer Explorer" })

require("neo-tree").setup({
  sources = { "filesystem", "buffers", "git_status" },
  open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
  filesystem = {
    bind_to_cwd = false,
    follow_current_file = { enabled = true },
    use_libuv_file_watcher = true,
  },
  window = {
    mappings = {
      ["l"] = "open",
      ["h"] = "close_node",
      ["<space>"] = "none",
      ["Y"] = {
        function(state)
          local node = state.tree:get_node()
          vim.fn.setreg("+", node:get_id(), "c")
        end,
        desc = "Copy Path to Clipboard",
      },
      ["O"] = {
        function(state)
          vim.ui.open(state.tree:get_node().path)
        end,
        desc = "Open with System Application",
      },
      ["P"] = { "toggle_preview", config = { use_float = false } },
    },
  },
  default_component_configs = {
    indent = {
      with_expanders = true,
      expander_collapsed = "",
      expander_expanded = "",
      expander_highlight = "NeoTreeExpander",
    },
    git_status = {
      symbols = {
        unstaged = "󰄱",
        staged = "󰱒",
      },
    },
  },
  event_handlers = {
    {
      event = require("neo-tree.events").FILE_MOVED,
      handler = function(data)
        require("snacks").rename.on_rename_file(data.source, data.destination)
      end,
    },
    {
      event = require("neo-tree.events").FILE_RENAMED,
      handler = function(data)
        require("snacks").rename.on_rename_file(data.source, data.destination)
      end,
    },
  },
})

--------------------------------------------------------------------------------
-- lazydev.nvim: LuaLS workspace library for Neovim plugin development
--------------------------------------------------------------------------------
require("lazydev").setup({
  library = {
    { path = "snacks.nvim", words = { "Snacks" } },
    { path = "nvim-lspconfig", words = { "lspconfig.settings" } },
  },
})

--------------------------------------------------------------------------------
-- nvim-treesitter-textobjects: `]f/]c/]a` style movement (main branch, no
-- built-in keymaps), with LazyVim's buffer-local keymap extension.
--------------------------------------------------------------------------------
local move_keys = {
  goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
  goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
  goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
  goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
}

require("nvim-treesitter-textobjects").setup({
  move = {
    enable = true,
    set_jumps = true,
  },
})

local function attach_textobjects(buf)
  local ft = vim.bo[buf].filetype
  if not ts_have(ft, "textobjects") then
    return
  end

  for method, keymaps in pairs(move_keys) do
    for key, query in pairs(keymaps) do
      local queries = type(query) == "table" and query or { query }
      local parts = {}
      for _, q in ipairs(queries) do
        local part = q:gsub("@", ""):gsub("%..*", "")
        part = part:sub(1, 1):upper() .. part:sub(2)
        parts[#parts + 1] = part
      end
      local desc = table.concat(parts, " or ")
      desc = (key:sub(1, 1) == "[" and "Prev " or "Next ") .. desc
      desc = desc .. (key:sub(2, 2) == key:sub(2, 2):upper() and " End" or " Start")

      map({ "n", "x", "o" }, key, function()
        if vim.wo.diff and key:find("[cC]") then
          return vim.cmd("normal! " .. key)
        end
        require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
      end, { buffer = buf, desc = desc, silent = true })
    end
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TreesitterTextobjects", { clear = true }),
  callback = function(ev)
    attach_textobjects(ev.buf)
  end,
})

for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(buf) then
    attach_textobjects(buf)
  end
end

--------------------------------------------------------------------------------
-- nvim-ts-autotag: auto close/rename HTML/JSX tags
--------------------------------------------------------------------------------
require("nvim-ts-autotag").setup({})

--------------------------------------------------------------------------------
-- crates.nvim: Cargo.toml intelligence
--------------------------------------------------------------------------------
require("crates").setup({
  completion = {
    crates = {
      enabled = true,
    },
  },
  lsp = {
    enabled = true,
    actions = true,
    completion = true,
    hover = true,
  },
})

--------------------------------------------------------------------------------
-- rustaceanvim: the rust-analyzer client (rust_analyzer is not enabled in
-- `vim.lsp.enable` to avoid a duplicate client)
--------------------------------------------------------------------------------
vim.g.rustaceanvim = {
  server = {
    on_attach = function(_, bufnr)
      -- Scheduled so these win over the generic `<leader>cR` LSP map.
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        map("n", "<leader>cR", function()
          vim.cmd.RustLsp("codeAction")
        end, { desc = "Code Action", buffer = bufnr })
        map("n", "<leader>dr", function()
          vim.cmd.RustLsp("debuggables")
        end, { desc = "Rust Debuggables", buffer = bufnr })
      end)
    end,
    default_settings = {
      ["rust-analyzer"] = {
        cargo = {
          allFeatures = true,
          loadOutDirsFromCheck = true,
          buildScripts = {
            enable = true,
          },
        },
        checkOnSave = true,
        diagnostics = {
          enable = true,
        },
        procMacro = {
          enable = true,
        },
        files = {
          exclude = {
            ".direnv",
            ".git",
            ".jj",
            ".github",
            ".gitlab",
            "bin",
            "node_modules",
            "target",
            "venv",
            ".venv",
          },
          watcher = "client",
        },
      },
    },
  },
}

--------------------------------------------------------------------------------
-- markdown-preview.nvim: needs a one-time build of its Node app
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "markdown-preview.nvim" and (kind == "install" or kind == "update") then
      vim.schedule(function()
        pcall(vim.cmd, "packadd markdown-preview.nvim")
        pcall(vim.fn["mkdp#util#install"])
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("MarkdownPreview", { clear = true }),
  pattern = "markdown",
  callback = function(ev)
    map("n", "<leader>cp", "<cmd>MarkdownPreviewToggle<cr>", { buffer = ev.buf, desc = "Markdown Preview" })
  end,
})

--------------------------------------------------------------------------------
-- render-markdown.nvim: in-buffer markdown rendering, toggled with `<leader>um`
--------------------------------------------------------------------------------
require("render-markdown").setup({
  code = {
    sign = false,
    width = "block",
    right_pad = 1,
  },
  heading = {
    sign = false,
    icons = {},
  },
  checkbox = {
    enabled = false,
  },
})

local render_markdown = require("render-markdown")
require("snacks")
  .toggle({
    name = "Render Markdown",
    get = render_markdown.get,
    set = render_markdown.set,
  })
  :map("<leader>um")
