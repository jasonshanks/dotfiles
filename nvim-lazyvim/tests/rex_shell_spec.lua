-- Stubbed Rex lifecycle tests for lua/plugins/ai.lua.
--
-- Run from the nvim directory:
--   nvim --headless -u NONE -l tests/rex_shell_spec.lua
--
-- No real Rex session, OpenCode server, or terminal is touched: `rex`, `curl`,
-- `lsof`, and `opencode serve` are answered by an in-memory model.

local script = debug.getinfo(1, "S").source:sub(2)
local ai_path = vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(script), "..", "lua", "plugins", "ai.lua"))

local project_dir = vim.fs.normalize(vim.fn.tempname() .. "-opencode-project")
local state_dir = vim.fs.normalize(vim.fn.tempname() .. "-opencode-state")
vim.fn.mkdir(vim.fs.joinpath(project_dir, ".git"), "p")
vim.fn.mkdir(state_dir, "p")
local state_path = vim.fs.joinpath(state_dir, "opencode-servers.json")
local key = vim.fs.root(project_dir, { ".git" }) or project_dir

local real = {
  system = vim.fn.system,
  systemlist = vim.fn.systemlist,
  executable = vim.fn.executable,
  getcwd = vim.fn.getcwd,
  stdpath = vim.fn.stdpath,
  notify = vim.notify,
  system_async = vim.system,
  create_user_command = vim.api.nvim_create_user_command,
  wait = vim.wait,
  jobstart = vim.fn.jobstart,
}

local last_status ---@type integer?
---`vim.v.shell_error` is read-only; drive it with a real (trivial) system call.
---@param code integer
local function set_status(code)
  if last_status ~= code then
    real.system({ "sh", "-c", "exit " .. code })
    last_status = code
  end
end

local SESSION = "session:test"
local world

local function reset(opts)
  opts = opts or {}
  world = {
    blocks = {},
    splits = {},
    sends = {},
    keys = {},
    focuses = {},
    closed = {},
    interrupts = 0,
    kills = 0,
    session_calls = {},
    pending = {},
    notifications = {},
    probes = 0,
    waits = {},
    herdr_send = nil,
    snacks_open = nil,
    server = {
      up = opts.server_up ~= false,
      port = opts.port or 4552,
      password = opts.password or "pw",
      pid = opts.pid or 9552,
      dir = key,
    },
  }
  for _, id in ipairs(opts.blocks or {}) do
    world.blocks[id] = { fg = opts.fg or "shell" }
  end
  last_status = nil
end

local function encode(value)
  return vim.fn.json_encode(value)
end

local function flag(cmd, name)
  for i = 1, #cmd - 1 do
    if cmd[i] == name then
      return cmd[i + 1]
    end
  end
  return nil
end

local function shell_block(id)
  world.blocks[id] = world.blocks[id] or { fg = "shell" }
  return world.blocks[id]
end

local FOREGROUNDS = {
  opencode = { name = "opencode", path = "/opt/homebrew/bin/opencode", argv0 = "opencode" },
  shell = { name = "fish", path = "/opt/homebrew/bin/fish", argv0 = "-fish" },
  login = { name = "login", path = "/usr/bin/login" },
  nvim = { name = "nvim", path = "/opt/homebrew/bin/nvim", argv0 = "nvim" },
  unknown = { name = "mystery", path = "/opt/homebrew/bin/mystery", argv0 = "mystery" },
}

local function fake_rex(cmd)
  local sub, action = cmd[2], cmd[3]
  local block_id = flag(cmd, "-b")

  if sub == "block" and action == "ls" then
    local ids = {}
    for id in pairs(world.blocks) do
      ids[#ids + 1] = { block_id = id }
    end
    return encode({ blocks = ids })
  end

  if sub == "block" and action == "call" then
    local block = block_id and world.blocks[block_id]
    if not block or block.broken_process then
      return ""
    end
    local fg = FOREGROUNDS[block.fg] or FOREGROUNDS.shell
    return encode({ foreground = fg, child = { name = "login" }, last_exit = vim.NIL })
  end

  if sub == "block" and action == "close" then
    world.closed[#world.closed + 1] = block_id
    world.blocks[block_id] = nil
    return encode({})
  end

  if sub == "split" then
    local id = "block:new" .. (#world.splits + 1)
    local dash = nil
    for i = 1, #cmd do
      if cmd[i] == "--" then
        dash = i
      end
    end
    world.splits[#world.splits + 1] = { block = id, anchor = flag(cmd, "-b"), command = dash and cmd[dash + 1] or nil }
    world.blocks[id] = { fg = dash and "opencode" or "shell" }
    return encode({ block_ids = { id }, window_id = "window:test" })
  end

  if sub == "send" then
    local text = cmd[#cmd]
    world.sends[#world.sends + 1] = { block = block_id, text = text }
    world.pending[block_id] = text
    return ""
  end

  if sub == "send-key" then
    local pressed = cmd[#cmd]
    world.keys[#world.keys + 1] = { block = block_id, key = pressed }
    local block = block_id and world.blocks[block_id]
    if pressed == "enter" and block then
      block.fg = (world.pending[block_id] or ""):find("opencode", 1, true) and "opencode" or "shell"
      world.pending[block_id] = nil
    elseif pressed == "ctrl+c" then
      world.interrupts = world.interrupts + 1
      if block then
        -- Match the live v2 TUI: the first interrupt while idle is often ignored.
        block.ctrl_c = (block.ctrl_c or 0) + 1
        if block.ctrl_c >= 2 then
          block.fg = "shell"
        end
      end
    end
    return ""
  end

  if sub == "focus" then
    world.focuses[#world.focuses + 1] = cmd[#cmd]
    return ""
  end

  if sub == "kill" then
    for id in pairs(world.blocks) do
      world.blocks[id] = nil
    end
    return ""
  end

  return ""
end

local function fake_curl(cmd)
  local url = cmd[#cmd] or ""
  local port = tonumber(url:match("127%.0%.0%.1:(%d+)/"))

  if flag(cmd, "-X") == "POST" and url:match("/api/session") then
    world.session_calls[#world.session_calls + 1] = url
    if url:match("/api/session/[^/]+/fork$") then
      return encode({ data = { id = "ses_forked" } })
    end
    return encode({ data = { id = "ses_child" } })
  end

  if url:match("/api/command$") then
    world.probes = world.probes + 1
    local auth = flag(cmd, "-u") or ""
    local password = auth:match("^opencode:(.*)$")
    local same_port = port == world.server.port
    if world.server.up and same_port and password == world.server.password then
      return encode({ location = { directory = world.server.dir } }) .. "\n200"
    end
    if world.server.up and same_port then
      return "unauthorized\n401"
    end
    return "\n000"
  end

  return "\n000"
end

local function fake_herdr(cmd)
  local action
  for i = 1, #cmd - 1 do
    if cmd[i] == "pane" then
      action = cmd[i + 1]
    end
  end
  if action == "current" then
    return encode({ pane_id = "pane:src" })
  end
  if action == "get" then
    return encode({ pane_id = cmd[#cmd], tab_id = "tab:1" })
  end
  if action == "send-text" then
    world.herdr_send = { pane = cmd[#cmd - 1], text = cmd[#cmd] }
    return encode({})
  end
  return encode({})
end

vim.fn.getcwd = function()
  return project_dir
end
vim.fn.stdpath = function(kind)
  return kind == "state" and state_dir or real.stdpath(kind)
end
vim.fn.executable = function(name)
  if name == "rex" or name == "tmux" or name == "herdr" then
    return 1
  end
  return real.executable(name)
end
vim.fn.system = function(cmd)
  if type(cmd) == "string" then
    local port, log = cmd:match("^opencode serve %-%-port (%d+) >(.+) 2>&1 &$")
    if port then
      log = log:gsub("^'(.*)'$", "%1"):gsub('^"(.*)"$', "%1")
      world.server.up = true
      world.server.port = tonumber(port)
      world.server.password = "pw" .. port
      world.server.pid = 9000 + tonumber(port)
      vim.fn.writefile({ "server listening", "server password " .. world.server.password }, log)
      set_status(0)
      return ""
    end
    set_status(0)
    return ""
  end

  local ok, out = pcall(function()
    if cmd[1] == "rex" then
      return fake_rex(cmd)
    elseif cmd[1] == "curl" then
      return fake_curl(cmd)
    elseif cmd[1] == "tmux" then
      return cmd[2] == "display-message" and "%1" or ""
    elseif cmd[1] == "herdr" then
      return fake_herdr(cmd)
    end
    return ""
  end)
  if not ok then
    set_status(1)
    return ""
  end
  set_status(0)
  return out
end
vim.fn.systemlist = function(cmd)
  if type(cmd) == "table" and cmd[1] == "lsof" then
    set_status(0)
    return world.server.up and { tostring(world.server.pid) } or {}
  end
  if type(cmd) == "table" and cmd[1] == "tmux" and cmd[2] == "list-panes" then
    set_status(0)
    return { "%1" }
  end
  return real.systemlist(cmd)
end
vim.wait = function(timeout, fn, interval)
  world.waits[#world.waits + 1] = timeout
  return real.wait(timeout, fn, interval)
end
vim.fn.jobstart = function(cmd, opts)
  opts = opts or {}
  local function reply(lines)
    vim.schedule(function()
      if opts.on_stdout then
        opts.on_stdout(1, lines)
      end
    end)
    return 1
  end
  if type(cmd) == "table" and cmd[1] == "tmux" then
    return reply({ "%1" })
  end
  if type(cmd) == "table" and cmd[1] == "herdr" and cmd[2] == "pane" and cmd[3] == "split" then
    return reply({ encode({ pane_id = "pane:tui" }) })
  end
  return real.jobstart(cmd, opts)
end
vim.system = function(cmd, opts)
  if type(cmd) == "table" and cmd[1] == "kill" then
    world.kills = world.kills + 1
    local pid = tonumber(cmd[3])
    if world.server.pid == pid then
      world.server.up = false
    end
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

vim.env.REX_SESSION = SESSION
vim.env.REX_BLOCK = "block:anchor"

local specs = dofile(ai_path)
local spec
for _, candidate in ipairs(specs) do
  if type(candidate) == "table" and candidate.keys then
    spec = candidate
  end
end
assert(spec, "opencode plugin spec not found")

local function mapping(lhs)
  for _, item in ipairs(spec.keys) do
    if item[1] == lhs then
      return item[2]
    end
  end
  error("missing mapping " .. lhs)
end

local commands = {}
vim.api.nvim_create_user_command = function(name, callback)
  commands[name] = callback
end
reset()
spec.config()
vim.api.nvim_create_user_command = real.create_user_command

local function set_state(entry)
  vim.fn.writefile({ encode({ [key] = entry }) }, state_path)
end

local function get_state()
  local lines = vim.fn.readfile(state_path)
  local decoded = vim.fn.json_decode(table.concat(lines, "\n"))
  return decoded[key] or {}
end

local function base_entry(overrides)
  return vim.tbl_extend("force", {
    mux = "rex",
    pane = "block:tui",
    rex_session = SESSION,
    rex_source = "block:anchor",
    rex_split = "right",
    port = 4552,
    password = "pw",
    server_pid = 9552,
  }, overrides or {})
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

local function assert_untouched(block_id)
  assert(world.blocks[block_id], "recorded block disappeared")
  for _, send in ipairs(world.sends) do
    assert(send.block ~= block_id, "typed text into unrelated block " .. block_id)
  end
  for _, key in ipairs(world.keys) do
    assert(key.block ~= block_id, "sent a key to unrelated block " .. block_id)
  end
end

local SELECTED = "ses_selected"

local function assert_selected_launch(block_id)
  local send = world.sends[1]
  assert(send and send.block == block_id, "did not launch in block " .. block_id)
  assert(send.text:find("--session", 1, true), "missing --session: " .. send.text)
  assert(send.text:find(SELECTED, 1, true), "did not launch the selected session: " .. send.text)
  assert(not send.text:find("ses_forked", 1, true), "launched a forked session: " .. send.text)
end

local function assert_no_session_mutation()
  assert(#world.session_calls == 0, "mutated sessions: " .. table.concat(world.session_calls, ", "))
end

test("running TUI is focused, not relaunched or re-split", function()
  reset({ blocks = { "block:anchor", "block:tui" }, fg = "opencode" })
  set_state(base_entry())
  mapping("<leader>ot")()
  assert(#world.splits == 0, "created a split")
  assert(#world.sends == 0, "sent a command")
  assert(world.focuses[#world.focuses] == "block:tui", "did not focus the TUI block")
end)

test("shell block is relaunched in place with a quoted command", function()
  reset({ blocks = { "block:anchor", "block:tui" }, fg = "shell", password = "p'w" })
  set_state(base_entry({ password = "p'w" }))
  mapping("<leader>ot")()
  assert(#world.splits == 0, "created a split instead of reusing the shell")
  assert(#world.sends == 1 and world.sends[1].block == "block:tui", "did not send into the same block")
  local argv = {
    "env",
    "OPENCODE_PASSWORD=p'w",
    "opencode",
    "--server",
    "http://127.0.0.1:4552",
  }
  local expected = {}
  for _, token in ipairs(argv) do
    expected[#expected + 1] = vim.fn.shellescape(token)
  end
  assert(world.sends[1].text == table.concat(expected, " "), "unexpected command line: " .. world.sends[1].text)
  assert(world.blocks["block:tui"].fg == "opencode", "TUI did not start")
  assert(world.focuses[#world.focuses] == "block:tui", "did not focus the reused block")
  assert(get_state().pane == "block:tui", "state lost the block id")
end)

test("an unrelated foreground block is left untouched and gets a fresh split", function()
  for _, fg in ipairs({ "nvim", "unknown" }) do
    reset({ blocks = { "block:anchor", "block:tui" } })
    world.blocks["block:tui"].fg = fg
    set_state(base_entry())
    mapping("<leader>ot")()
    assert_untouched("block:tui")
    assert(world.blocks["block:tui"].fg == fg, "changed the unrelated block foreground")
    assert(#world.closed == 0, "closed the unrelated block")
    assert(#world.splits == 1, "expected one fresh split for " .. fg .. ", got " .. #world.splits)
    assert(world.splits[1].anchor == "block:anchor", "wrong anchor for " .. fg)
    local new_block = world.splits[1].block
    assert(world.sends[1].block == new_block, "did not launch in the fresh block for " .. fg)
    assert(get_state().pane == new_block, "state did not move to the fresh block for " .. fg)
  end
end)

test("unreadable process metadata is never typed into", function()
  reset({ blocks = { "block:anchor", "block:tui" } })
  world.blocks["block:tui"].broken_process = true
  set_state(base_entry())
  mapping("<leader>ot")()
  assert_untouched("block:tui")
  assert(#world.closed == 0, "closed the block")
  assert(#world.splits == 1, "expected one fresh split")
  assert(get_state().pane == world.splits[1].block, "state did not move to the fresh block")
end)

test("a closed block gets exactly one new split anchored beside nvim", function()
  reset({ blocks = { "block:anchor" } })
  set_state(base_entry({ pane = "block:gone" }))
  mapping("<leader>ot")()
  assert(#world.splits == 1, "expected one split, got " .. #world.splits)
  assert(world.splits[1].anchor == "block:anchor", "wrong anchor: " .. tostring(world.splits[1].anchor))
  local new_block = world.splits[1].block
  assert(world.sends[1].block == new_block, "launched outside the new block")
  assert(get_state().pane == new_block, "state did not record the new block")
end)

test("restore interrupts a running TUI and relaunches in the same block", function()
  reset({ blocks = { "block:anchor", "block:tui" }, fg = "opencode" })
  set_state(base_entry())
  commands.OpencodeRestore({ args = SELECTED })
  assert(world.interrupts >= 2, "did not retry the interrupt until the shell returned")
  assert(#world.closed == 0, "closed the recorded block")
  assert(#world.splits == 0, "created a new split")
  assert_selected_launch("block:tui")
  assert_no_session_mutation()
  assert(world.kills == 0, "stopped the shared server to switch session")
  assert(world.server.up, "shared server went down")
  assert(world.sends[1].text:find("OPENCODE_PASSWORD=pw", 1, true), "did not keep the live password")
  assert(not world.sends[1].text:find("pw4552", 1, true), "restarted the server instead of reusing it")
  assert(get_state().pane == "block:tui", "state lost the block id")
end)

test("restore does not interrupt a block already at its shell", function()
  reset({ blocks = { "block:anchor", "block:tui" }, fg = "shell" })
  set_state(base_entry())
  commands.OpencodeRestore({ args = SELECTED })
  assert(world.interrupts == 0, "sent ctrl+c to a shell")
  assert(#world.closed == 0, "closed the recorded block")
  assert(#world.splits == 0, "created a new split")
  assert_selected_launch("block:tui")
  assert_no_session_mutation()
  assert(world.kills == 0, "stopped the shared server to switch session")
end)

test("restore leaves an unrelated foreground block untouched and splits", function()
  for _, fg in ipairs({ "nvim", "unknown" }) do
    reset({ blocks = { "block:anchor", "block:tui" } })
    world.blocks["block:tui"].fg = fg
    set_state(base_entry())
    commands.OpencodeRestore({ args = SELECTED })
    assert(world.interrupts == 0, "interrupted an unrelated program for " .. fg)
    assert_untouched("block:tui")
    assert(world.blocks["block:tui"].fg == fg, "changed the unrelated block foreground")
    assert(#world.closed == 0, "closed the unrelated block")
    assert(#world.splits == 1, "expected one fresh split for " .. fg .. ", got " .. #world.splits)
    assert(world.splits[1].anchor == "block:anchor", "wrong anchor for " .. fg)
    local new_block = world.splits[1].block
    assert_selected_launch(new_block)
    assert_no_session_mutation()
    assert(world.kills == 0, "stopped the shared server for " .. fg)
    assert(get_state().pane == new_block, "state did not move to the fresh block for " .. fg)
  end
end)

test("restore creates a split only when the recorded block is gone", function()
  reset({ blocks = { "block:anchor" } })
  set_state(base_entry({ pane = "block:gone" }))
  commands.OpencodeRestore({ args = SELECTED })
  assert(#world.closed == 0, "closed a block")
  assert(#world.splits == 1, "expected one split, got " .. #world.splits)
  assert(world.splits[1].anchor == "block:anchor", "wrong anchor")
  assert_selected_launch(world.splits[1].block)
  assert_no_session_mutation()
  assert(world.kills == 0, "stopped the shared server")
  assert(get_state().pane == world.splits[1].block, "state did not record the new block")
end)

test("restore starts a server only when none is listening", function()
  reset({ blocks = { "block:anchor", "block:tui" }, fg = "shell", server_up = false })
  set_state(base_entry())
  commands.OpencodeRestore({ args = SELECTED })
  assert_no_session_mutation()
  assert(world.server.up, "did not start a server")
  assert(world.kills == 0, "killed a server")
  assert(#world.splits == 0, "created a split instead of reusing the shell")
  assert_selected_launch("block:tui")
  assert(world.sends[1].text:find("OPENCODE_PASSWORD=pw4552", 1, true), "did not use the new server password")
  assert(get_state().pane == "block:tui", "state lost the block id")
end)

test("restore probes the resolved port once", function()
  reset({ blocks = { "block:anchor", "block:tui" }, fg = "shell" })
  set_state(base_entry())
  commands.OpencodeRestore({ args = SELECTED })
  assert(world.probes == 2, "expected one resolve probe plus one restore probe, got " .. world.probes)
end)

local function use_mux(kind)
  vim.env.REX_SESSION, vim.env.REX_BLOCK = nil, nil
  vim.env.TMUX, vim.env.HERDR_PANE_ID = nil, nil
  if kind == "tmux" then
    vim.env.TMUX = "/tmp/tmux-test"
  elseif kind == "herdr" then
    vim.env.HERDR_PANE_ID = "pane:src"
  end
end

test("snacks fallback does not wait for a pane", function()
  use_mux("snacks")
  reset({ server_up = true })
  package.loaded["snacks.terminal"] = {
    open = function(argv, opts)
      world.snacks_open = { argv = argv, opts = opts }
    end,
  }
  package.loaded["opencode"] = { command = function() end }
  set_state({ mux = "snacks", pane = "", port = 4552, password = "pw" })
  mapping("<leader>on")()
  assert(world.snacks_open, "did not open the snacks terminal")
  assert(#world.waits == 0, "waited for a pane that snacks never records")
end)

test("tmux waits for its asynchronously captured pane", function()
  use_mux("tmux")
  reset({ server_up = true })
  package.loaded["opencode"] = { command = function() end }
  set_state({ mux = "tmux", pane = "", port = 4552, password = "pw" })
  mapping("<leader>on")()
  assert(vim.tbl_contains(world.waits, 3000), "did not wait for the tmux pane")
  assert(get_state().pane == "%1", "did not record the tmux pane")
end)

test("herdr sends a shell-quoted line and only waits for its split", function()
  use_mux("herdr")
  reset({ server_up = true, password = "p'w" })
  package.loaded["opencode"] = { command = function() end }
  set_state({ mux = "herdr", pane = "", port = 4552, password = "p'w" })
  mapping("<leader>on")()
  assert(vim.tbl_contains(world.waits, 10000), "did not wait for the herdr split")
  assert(not vim.tbl_contains(world.waits, 3000), "waited for the herdr pane twice")
  local argv = { "env", "OPENCODE_PASSWORD=p'w", "opencode", "--server", "http://127.0.0.1:4552" }
  local expected = {}
  for _, token in ipairs(argv) do
    expected[#expected + 1] = vim.fn.shellescape(token)
  end
  assert(world.herdr_send, "did not send the TUI command")
  assert(world.herdr_send.text == table.concat(expected, " "), "unquoted herdr line: " .. world.herdr_send.text)
end)

vim.env.REX_SESSION, vim.env.REX_BLOCK = SESSION, "block:anchor"
vim.env.TMUX, vim.env.HERDR_PANE_ID = nil, nil

vim.fn.delete(project_dir, "rf")
vim.fn.delete(state_dir, "rf")

io.write(("\n%d passed, %d failed\n"):format(passed, failed))
if failed > 0 then
  os.exit(1)
end
