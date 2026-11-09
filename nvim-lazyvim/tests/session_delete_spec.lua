-- Stubbed tests for the `<leader>os` session picker and Ask completion config.
--
-- Run from the nvim directory:
--   nvim --headless -u NONE -l tests/session_delete_spec.lua
--
-- No real OpenCode session is listed or deleted. `opencode session delete` is
-- answered by an in-memory stub, and the picker itself is stubbed.

local script = debug.getinfo(1, "S").source:sub(2)
local nvim_dir = vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(script), ".."))
local ai_path = vim.fs.joinpath(nvim_dir, "lua", "plugins", "ai.lua")
local lsp_path = vim.fs.joinpath(nvim_dir, "lua", "plugins", "lsp.lua")

local project_dir = vim.fs.normalize(vim.fn.tempname() .. "-opencode-project")
vim.fn.mkdir(vim.fs.joinpath(project_dir, ".git"), "p")

local real = {
  getcwd = vim.fn.getcwd,
  jobstart = vim.fn.jobstart,
  notify = vim.notify,
  system = vim.system,
}

local world = {}

local function reset()
  world = {
    pickers = {},
    confirm = nil,
    deletes = {},
    notifications = {},
    closes = 0,
  }
end

local function find_spec(specs, name)
  for _, spec in ipairs(specs) do
    if spec[1] == name then
      return spec
    end
  end
end

local function mapping(spec, lhs)
  for _, item in ipairs(spec.keys) do
    if item[1] == lhs then
      return item[2]
    end
  end
  error("missing mapping " .. lhs)
end

local passed, failed = 0, 0
local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    io.write("ok   " .. name .. "\n")
  else
    failed = failed + 1
    io.write("FAIL " .. name .. "\n     " .. tostring(err) .. "\n")
  end
end

local function wait_for(predicate, message)
  assert(vim.wait(1000, predicate, 10), message)
end

-- ---------------------------------------------------------------------------
-- Static/headless: Blink sources exclude Codeium for the Ask input.
-- ---------------------------------------------------------------------------
test("Blink opencode_ask sources keep lsp/buffer and exclude codeium", function()
  local specs = dofile(lsp_path)
  local blink = find_spec(specs, "saghen/blink.cmp")
  assert(blink, "blink.cmp spec not found")

  local sources = blink.opts.sources
  assert(sources, "blink sources missing")
  assert(vim.tbl_contains(sources.default, "codeium"), "global default should still include codeium")

  local ask = sources.per_filetype and sources.per_filetype.opencode_ask
  assert(ask, "missing per_filetype.opencode_ask")
  assert(vim.tbl_contains(ask, "lsp"), "opencode_ask lost the lsp source")
  assert(vim.tbl_contains(ask, "buffer"), "opencode_ask lost the buffer source")
  assert(not vim.tbl_contains(ask, "codeium"), "opencode_ask must not include codeium")
end)

-- ---------------------------------------------------------------------------
-- Static/headless: Codeium virtual text is disabled for Ask.
-- ---------------------------------------------------------------------------
test("Codeium virtual text is disabled for opencode_ask", function()
  local specs = dofile(ai_path)
  local windsurf = find_spec(specs, "Exafunction/windsurf.nvim")
  assert(windsurf, "windsurf.nvim spec not found")

  local captured
  local previous = package.loaded["codeium"]
  package.loaded["codeium"] = {
    setup = function(opts)
      captured = opts
    end,
  }
  local ok, err = pcall(windsurf.config)
  package.loaded["codeium"] = previous
  assert(ok, "windsurf config failed: " .. tostring(err))
  assert(captured, "codeium.setup was not called")
  assert(captured.enable_cmp_source == false, "enable_cmp_source should stay false")

  local filetypes = captured.virtual_text and captured.virtual_text.filetypes
  assert(filetypes, "virtual_text.filetypes missing")
  assert(filetypes.opencode_ask == false, "opencode_ask virtual text should be false")
  assert(filetypes.snacks_input == false, "snacks_input virtual text should be false")

  -- Exercise Codeium's actual predicate when the plugin source is installed.
  local lazy_lua = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "windsurf.nvim", "lua")
  if vim.uv.fs_stat(lazy_lua) then
    package.path = lazy_lua .. "/?.lua;" .. lazy_lua .. "/?/init.lua;" .. package.path
    local config_ok, config = pcall(require, "codeium.config")
    local vt_ok, virtual_text = pcall(require, "codeium.virtual_text")
    if config_ok and vt_ok then
      config.setup({ virtual_text = { filetypes = filetypes } })
      local buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].filetype = "opencode_ask"
      assert(virtual_text.filetype_enabled(buf) == false, "filetype_enabled(opencode_ask) should be false")
      vim.bo[buf].filetype = "lua"
      assert(virtual_text.filetype_enabled(buf) == true, "normal filetypes should remain enabled")
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end)

-- ---------------------------------------------------------------------------
-- Picker: <C-x> confirms, then deletes only the selected id.
-- ---------------------------------------------------------------------------
vim.fn.getcwd = function()
  return project_dir
end

local sessions = {
  {
    id = "ses_one",
    title = "One",
    directory = project_dir,
    updated = os.time() * 1000,
  },
}
local list_json = vim.json.encode(sessions)

vim.fn.jobstart = function(cmd, opts)
  if type(cmd) == "table" and cmd[1] == "opencode" and cmd[2] == "session" and cmd[3] == "list" then
    if opts.on_stdout then
      opts.on_stdout(0, { list_json })
    end
    if opts.on_exit then
      opts.on_exit(0, 0)
    end
    return 1
  end
  error("unexpected jobstart: " .. vim.inspect(cmd))
end

vim.system = function(cmd, opts, on_exit)
  world.deletes[#world.deletes + 1] = { cmd = cmd, opts = opts }
  if on_exit then
    on_exit(world.delete_reply or { code = 0, stdout = "", stderr = "" })
  end
  return {
    wait = function()
      return { code = 0 }
    end,
  }
end

vim.notify = function(msg, level)
  world.notifications[#world.notifications + 1] = { msg = msg, level = level }
end

package.loaded["snacks.picker"] = {
  pick = function(opts)
    local picker = {
      opts = opts,
      closed = false,
      item = opts.items and opts.items[1],
    }
    function picker:current()
      return self.item
    end
    function picker:close()
      self.closed = true
      world.closes = world.closes + 1
    end
    world.pickers[#world.pickers + 1] = picker
    return picker
  end,
}
package.loaded["snacks.picker.util"] = {
  confirm = function(prompt, fn)
    world.confirm = { prompt = prompt, fn = fn }
  end,
}

local specs = dofile(ai_path)
local opencode = find_spec(specs, "NickvanDyke/opencode.nvim")
assert(opencode, "opencode.nvim spec not found")
local open_picker = mapping(opencode, "<leader>os")

local function start_picker()
  reset()
  open_picker()
  assert(#world.pickers == 1, "picker was not created")
  local picker = world.pickers[1]
  local opts = picker.opts

  local input = opts.win and opts.win.input and opts.win.input.keys
  local list = opts.win and opts.win.list and opts.win.list.keys
  assert(input and input["<C-x>"], "missing <C-x> input mapping")
  assert(list and list["<C-x>"], "missing <C-x> list mapping")
  assert(input["<C-x>"][1] == "delete_session", "input mapping does not target the delete action")
  assert(list["<C-x>"][1] == "delete_session", "list mapping does not target the delete action")
  assert(type(opts.actions and opts.actions.delete_session) == "function", "delete_session action missing")
  return picker
end

test("<C-x> prompts before deleting and cancel performs no CLI delete", function()
  local picker = start_picker()
  picker.opts.actions.delete_session(picker, picker:current())

  assert(world.confirm, "delete action did not ask for confirmation")
  local prompt = world.confirm.prompt
  assert(prompt:find("ses_one", 1, true), "prompt does not name the selected session")
  assert(prompt:find("child sessions", 1, true), "prompt does not warn about child sessions")
  assert(prompt:find("no undo", 1, true), "prompt does not warn that deletion is permanent")
  assert(#world.deletes == 0, "delete ran before confirmation")

  -- Cancellation: the confirm callback is never invoked.
  vim.wait(50, function()
    return false
  end, 10)
  assert(#world.deletes == 0, "cancelled delete still called the CLI")
  assert(not picker.closed, "cancelled delete closed the picker")
end)

test("success deletes only the selected id and refreshes the picker", function()
  local picker = start_picker()
  world.delete_reply = { code = 0, stdout = "", stderr = "" }
  picker.opts.actions.delete_session(picker, picker:current())
  world.confirm.fn()

  wait_for(function()
    return #world.deletes == 1 and #world.pickers == 2
  end, "successful delete did not reopen the picker")

  local delete = world.deletes[1]
  assert(vim.deep_equal(delete.cmd, { "opencode", "session", "delete", "ses_one" }), "unexpected delete argv")
  assert(delete.opts.cwd == project_dir, "delete did not run in the project cwd")
  assert(picker.closed, "old picker was not closed before refresh")
  assert(world.notifications[#world.notifications].level == vim.log.levels.INFO, "success was not reported as info")
end)

test("failure keeps the picker open and reports an error", function()
  local picker = start_picker()
  world.delete_reply = { code = 1, stdout = "", stderr = "boom" }
  picker.opts.actions.delete_session(picker, picker:current())
  world.confirm.fn()

  wait_for(function()
    return #world.deletes == 1 and #world.notifications > 0
  end, "failed delete did not report")

  assert(not picker.closed, "failed delete closed the picker")
  assert(#world.pickers == 1, "failed delete refreshed the picker")
  local last = world.notifications[#world.notifications]
  assert(last.level == vim.log.levels.ERROR, "failure was not reported as an error")
  assert(last.msg:find("boom", 1, true), "failure notification lacks stderr detail")
end)

vim.fn.getcwd = real.getcwd
vim.fn.jobstart = real.jobstart
vim.notify = real.notify
vim.system = real.system

io.write(("\n%d passed, %d failed\n"):format(passed, failed))
if failed > 0 then
  vim.cmd("cquit 1")
end
