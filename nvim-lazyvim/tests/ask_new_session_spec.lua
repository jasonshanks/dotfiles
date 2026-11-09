-- Stubbed tests for `<leader>oa` creating a fresh root only after Ask submission.
--
-- Run from the nvim directory:
--   nvim --headless -u NONE -l tests/ask_new_session_spec.lua
--
-- No real OpenCode server, session, prompt, Rex block, or snack input is touched.

local script = debug.getinfo(1, "S").source:sub(2)
local nvim_dir = vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(script), ".."))
local ai_path = vim.fs.joinpath(nvim_dir, "lua", "plugins", "ai.lua")

local project_dir = vim.fs.normalize(vim.fn.tempname() .. "-opencode-ask-project")
local state_dir = vim.fs.normalize(vim.fn.tempname() .. "-opencode-ask-state")
vim.fn.mkdir(vim.fs.joinpath(project_dir, ".git"), "p")
vim.fn.mkdir(state_dir, "p")
local state_path = vim.fs.joinpath(state_dir, "opencode-servers.json")
local key = vim.fs.root(project_dir, { ".git" }) or project_dir
local SESSION = "session:ask-test"

local real = {
  getcwd = vim.fn.getcwd,
  stdpath = vim.fn.stdpath,
  executable = vim.fn.executable,
  system = vim.fn.system,
  notify = vim.notify,
}

-- ---------------------------------------------------------------------------
-- Minimal OpenCode-style promise stub (synchronous, supports deferred values).
-- ---------------------------------------------------------------------------
local Promise = {}
Promise.__index = Promise

local function new_promise(executor)
  local p = setmetatable({ status = "pending", callbacks = {} }, Promise)

  local function settle(status, value)
    if p.status ~= "pending" then
      return
    end
    p.status, p.value = status, value
    local callbacks = p.callbacks
    p.callbacks = {}
    for _, callback in ipairs(callbacks) do
      callback()
    end
  end

  local function resolve(value)
    if getmetatable(value) == Promise then
      value
        :next(function(v)
          settle("fulfilled", v)
        end)
        :catch(function(err)
          settle("rejected", err)
        end)
      return
    end
    settle("fulfilled", value)
  end

  local function reject(reason)
    settle("rejected", reason)
  end

  executor(resolve, reject)
  return p
end

local function chain(self, status, fn)
  return new_promise(function(resolve, reject)
    local function run()
      if self.status == status then
        local ok, result = pcall(fn, self.value)
        if not ok then
          return reject(result)
        end
        return resolve(result)
      elseif self.status == "pending" then
        self.callbacks[#self.callbacks + 1] = run
      elseif status == "fulfilled" then
        reject(self.value)
      else
        resolve(self.value)
      end
    end
    run()
  end)
end

function Promise:next(fn)
  return chain(self, "fulfilled", fn)
end

function Promise:catch(fn)
  return chain(self, "rejected", fn)
end

Promise.new = new_promise
Promise.resolve = function(value)
  return new_promise(function(resolve)
    resolve(value)
  end)
end
Promise.reject = function(reason)
  return new_promise(function(_, reject)
    reject(reason)
  end)
end

-- ---------------------------------------------------------------------------
-- World / stubs
-- ---------------------------------------------------------------------------
local world

local server = {
  requests = {},
  prompts = {},
}

local function reset()
  server.requests, server.prompts = {}, {}
  world = {
    blocks = {
      ["block:anchor"] = { fg = "shell" },
      ["block:tui"] = { fg = "opencode" },
    },
    sends = {},
    keys = {},
    focuses = {},
    splits = {},
    notifications = {},
    events = {},
    roots = 0,
    ask_default = nil,
    ask_reply = nil,
    rendered_input = nil,
    cleared = false,
    resumed = false,
  }
end

local function seed_state(overrides)
  local entry = vim.tbl_extend("force", {
    mux = "rex",
    pane = "block:tui",
    rex_session = SESSION,
    rex_source = "block:anchor",
    rex_split = "right",
    port = 4552,
    password = "pw",
  }, overrides or {})
  vim.fn.writefile({ vim.json.encode({ [key] = entry }) }, state_path)
end

local function flag(cmd, name)
  for i = 1, #cmd - 1 do
    if cmd[i] == name then
      return cmd[i + 1]
    end
  end
end

local FOREGROUNDS = {
  opencode = { name = "opencode", path = "/opt/homebrew/bin/opencode", argv0 = "opencode" },
  shell = { name = "fish", path = "/opt/homebrew/bin/fish", argv0 = "-fish" },
}

local function fake_rex(cmd)
  local sub, action = cmd[2], cmd[3]
  local block_id = flag(cmd, "-b")

  if sub == "block" and action == "ls" then
    local blocks = {}
    for id in pairs(world.blocks) do
      blocks[#blocks + 1] = { block_id = id }
    end
    return vim.json.encode({ blocks = blocks })
  end

  if sub == "block" and action == "call" then
    local block = world.blocks[block_id]
    if not block then
      return ""
    end
    return vim.json.encode({ foreground = FOREGROUNDS[block.fg] or FOREGROUNDS.shell })
  end

  if sub == "split" then
    local id = "block:new" .. (#world.splits + 1)
    world.splits[#world.splits + 1] = { block = id, anchor = block_id, cmd = cmd }
    world.blocks[id] = { fg = "shell" }
    return vim.json.encode({ block_ids = { id } })
  end

  if sub == "send" then
    local text = cmd[#cmd]
    world.sends[#world.sends + 1] = { block = block_id, text = text }
    world.events[#world.events + 1] = "tui-send"
    world.blocks[block_id].pending = text
    return ""
  end

  if sub == "send-key" then
    local pressed = cmd[#cmd]
    world.keys[#world.keys + 1] = { block = block_id, key = pressed }
    local block = world.blocks[block_id]
    if pressed == "ctrl+c" then
      block.fg = "shell"
    elseif pressed == "enter" then
      block.fg = (block.pending or ""):find("opencode", 1, true) and "opencode" or "shell"
      block.pending = nil
    end
    return ""
  end

  if sub == "focus" then
    world.focuses[#world.focuses + 1] = cmd[#cmd]
    return ""
  end

  return ""
end

vim.fn.getcwd = function()
  return project_dir
end
vim.fn.stdpath = function(kind)
  return kind == "state" and state_dir or real.stdpath(kind)
end
vim.fn.executable = function(name)
  return name == "rex" and 1 or real.executable(name)
end
vim.fn.system = function(cmd)
  if type(cmd) == "string" then
    return ""
  end
  if cmd[1] == "curl" then
    -- The server is up and belongs to this project; start_server is never needed.
    return vim.json.encode({ location = { directory = project_dir } }) .. "\n200"
  end
  if cmd[1] == "rex" then
    return fake_rex(cmd)
  end
  return ""
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

local function mapping(lhs, mode)
  for _, item in ipairs(spec.keys) do
    if item[1] == lhs and item.mode == mode then
      return item[2]
    end
  end
  error("missing mapping " .. lhs .. " for mode " .. tostring(mode))
end

function server:request(path, method, body)
  self.requests[#self.requests + 1] = { path = path, method = method, body = body }
  if path == "/api/session" and method == "POST" then
    world.roots = world.roots + 1
    world.events[#world.events + 1] = "root"
    return Promise.resolve({ data = { id = "ses_new" .. world.roots } })
  end
  return Promise.reject("unexpected request " .. tostring(path))
end
function server:prompt(id, text)
  self.prompts[#self.prompts + 1] = { id = id, text = text }
  world.events[#world.events + 1] = "prompt"
  return Promise.resolve({})
end

local fake_context
package.loaded["opencode.promise"] = Promise
package.loaded["opencode.config"] = { opts = { server = {} } }
package.loaded["opencode.server"] = { connected = nil }
package.loaded["opencode.server.discovery"] = {
  get = function()
    return Promise.resolve(server)
  end,
}
package.loaded["opencode.context"] = {
  new = function(_)
    fake_context = {
      render = function(_, text)
        world.rendered_input = text
        return {
          output = {
            plaintext = function()
              return "CONTEXT(" .. text .. ")"
            end,
          },
        }
      end,
      clear = function()
        world.cleared = true
      end,
      resume = function()
        world.resumed = true
      end,
    }
    return fake_context
  end,
}
package.loaded["opencode.ui.ask"] = {
  ask = function(default, _)
    world.ask_default = default
    return world.ask_reply
  end,
}

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

local function deferred_ask()
  local resolve, reject
  world.ask_reply = Promise.new(function(res, rej)
    resolve, reject = res, rej
  end)
  return resolve, reject
end

local normal_ask = mapping("<leader>oa", "n")
local visual_ask = mapping("<leader>oa", "v")
assert(normal_ask, "normal <leader>oa mapping missing")
assert(visual_ask, "visual <leader>oa mapping missing")

test("cancel opens no session and sends no prompt", function()
  reset()
  seed_state()
  local _, reject = deferred_ask()
  normal_ask()

  assert(world.ask_default == "@cursor: ", "normal Ask default missing")
  assert(world.roots == 0, "root created before submission")
  assert(#server.requests == 0, "API request sent before submission")
  assert(#world.sends == 0, "TUI launched before submission")

  reject("cancelled")
  assert(world.roots == 0, "cancelled Ask created a root")
  assert(#server.requests == 0, "cancelled Ask sent an API request")
  assert(#server.prompts == 0, "cancelled Ask sent a prompt")
  assert(#world.sends == 0, "cancelled Ask launched a TUI")
  assert(world.notifications[#world.notifications].level == vim.log.levels.ERROR, "cancel was not reported")
end)

test("normal Ask creates one root and prompts that exact id without focus", function()
  reset()
  seed_state()
  local resolve = deferred_ask()
  normal_ask()

  assert(world.ask_default == "@cursor: ", "normal Ask default missing")
  assert(world.roots == 0, "root created before submission")
  resolve("explain this")

  assert(world.roots == 1, "submit did not create exactly one root")
  assert(
    vim.deep_equal(server.requests[1], { path = "/api/session", method = "POST", body = {} }),
    "unexpected root request"
  )
  assert(#server.prompts == 1, "prompt was not sent")
  assert(server.prompts[1].id == "ses_new1", "prompt did not target the new root")
  assert(server.prompts[1].text == "CONTEXT(explain this)", "rendered context was not used")
  assert(world.rendered_input == "explain this", "render did not receive the submitted input")
  assert(world.cleared, "context was not cleared after success")
  assert(#world.sends == 1 and world.sends[1].block == "block:tui", "TUI was not switched in place")
  assert(world.sends[1].text:find("--session", 1, true), "TUI argv lacks --session")
  assert(world.sends[1].text:find("ses_new1", 1, true), "TUI did not switch to the new root")
  assert(#world.focuses == 0, "Ask stole focus into a Rex block")
  assert(
    vim.deep_equal(world.events, { "root", "tui-send", "prompt" }),
    "flow order was " .. table.concat(world.events, ",")
  )
end)

test("visual Ask uses selection context and the same new-root flow", function()
  reset()
  seed_state()
  local resolve = deferred_ask()
  visual_ask()

  assert(world.ask_default == "@selection: ", "visual Ask default missing")
  assert(world.roots == 0, "root created before submission")
  resolve("selected code")

  assert(world.roots == 1, "visual Ask did not create exactly one root")
  assert(#server.prompts == 1, "visual prompt was not sent")
  assert(server.prompts[1].id == "ses_new1", "visual prompt did not target the new root")
  assert(server.prompts[1].text == "CONTEXT(selected code)", "visual rendered context was not used")
  assert(#world.sends == 1 and world.sends[1].text:find("ses_new1", 1, true), "visual TUI did not switch")
  assert(#world.focuses == 0, "visual Ask stole focus into a Rex block")
end)

test("new Rex split for Ask uses --focus=false", function()
  reset()
  seed_state({ pane = "block:gone" })
  local resolve = deferred_ask()
  normal_ask()
  resolve("fresh")

  assert(world.roots == 1, "Ask did not create one root")
  assert(#world.splits == 1, "expected one new Rex split")
  assert(vim.tbl_contains(world.splits[1].cmd, "--focus=false"), "new Rex split did not disable focus")
  assert(#world.focuses == 0, "Ask focused a Rex block")
  assert(world.sends[1].block == world.splits[1].block, "TUI did not launch in the new block")
  assert(server.prompts[1].id == "ses_new1", "prompt did not target the new root")
end)

vim.fn.getcwd = real.getcwd
vim.fn.stdpath = real.stdpath
vim.fn.executable = real.executable
vim.fn.system = real.system
vim.notify = real.notify

io.write(("\n%d passed, %d failed\n"):format(passed, failed))
if failed > 0 then
  vim.cmd("cquit 1")
end
