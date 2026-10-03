-- 🤖 AI: AI-assisted coding and LLM integrations

local OC_HOST = "127.0.0.1"
local OC_PORT_MIN, OC_PORT_MAX = 4100, 4999
local OC_PORT_SLOTS = 20
local OC_STATE_PATH = vim.fs.joinpath(vim.fn.stdpath("state"), "opencode-servers.json")
-- LuaJIT keeps `unpack` global and only sets `table.unpack` under 5.2 compatibility.
local unpack = unpack or table.unpack

---@class ai.OpencodeEntry
---@field port? integer
---@field mux? "tmux"|"herdr"|"snacks"
---@field pane? string
---@field src? string herdr only: the pane the TUI was split from
---@field dir? string herdr only: the direction it was split in
---@field url? string

---@param msg string
---@param level? integer defaults to INFO
local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "opencode" })
end

---@param port integer
---@return string
local function oc_url(port)
  return "http://" .. OC_HOST .. ":" .. port
end

---@param path any
---@return string
local function realpath(path)
  if type(path) ~= "string" or path == "" then
    return ""
  end
  -- macOS `/var` vs `/private/var` means equality checks need resolved paths.
  local ok, resolved = pcall(vim.uv.fs_realpath, path)
  return vim.fs.normalize((ok and type(resolved) == "string") and resolved or path)
end

---Project identity for opencode: the git root when there is one, else the cwd.
---@return string key
---@return string cwd
local function project()
  local cwd = vim.fn.getcwd()
  if type(cwd) ~= "string" or cwd == "" then
    cwd = vim.fs.normalize(vim.uv.cwd() or ".")
  end
  return vim.fs.root(cwd, { ".git" }) or vim.fs.normalize(cwd), cwd
end

---Stable per-project port: djb2 over the project key, folded into 4100-4999.
---@param key string
---@return integer
local function hash_port(key)
  local hash = 5381
  for i = 1, #key do
    hash = (hash * 33 + key:byte(i)) % 4294967296
  end
  return OC_PORT_MIN + (hash % (OC_PORT_MAX - OC_PORT_MIN + 1))
end

---Does the directory a port serves belong to this project? Opencode resolves the
---closest parent match, so either direction counts.
---@param dir string?
---@param key string
---@param cwd string
---@return boolean
local function same_project(dir, key, cwd)
  if type(dir) ~= "string" or dir == "" then
    return false
  end
  local served, root, here = realpath(dir), realpath(key), realpath(cwd)
  return served == root
    or here == served
    or here:sub(1, #served + 1) == served .. "/"
    or served:sub(1, #root + 1) == root .. "/"
end

---Ask a port which project it serves: the directory it answers with, or nil when
---nothing is listening there.
---@param port integer
---@param cwd string
---@return string?
local function probe(port, cwd)
  local ok, reply = pcall(vim.fn.system, {
    "curl",
    "-s",
    "-m",
    "2",
    "-H",
    "x-opencode-directory: " .. vim.uri_encode(cwd),
    "http://" .. OC_HOST .. ":" .. port .. "/api/command",
  })
  if not ok or type(reply) ~= "string" or vim.trim(reply) == "" then
    return nil
  end
  local decoded_ok, decoded = pcall(vim.json.decode, reply)
  local location = decoded_ok and type(decoded) == "table" and decoded.location
  local dir = type(location) == "table" and location.directory
  return type(dir) == "string" and dir ~= "" and dir or nil
end

---@return table<string, ai.OpencodeEntry>
local function read_state()
  local ok, lines = pcall(vim.fn.readfile, OC_STATE_PATH)
  if not ok or type(lines) ~= "table" or #lines == 0 then
    return {}
  end
  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  return (decoded_ok and type(decoded) == "table") and decoded or {}
end

---@param state table<string, ai.OpencodeEntry>
local function write_state(state)
  pcall(vim.fn.mkdir, vim.fn.fnamemodify(OC_STATE_PATH, ":h"), "p")
  pcall(vim.fn.writefile, { vim.fn.json_encode(state) }, OC_STATE_PATH)
end

---Persisted port first while it still serves this project, else the first free (or
---self-serving) slot in the window starting at the hashed candidate.
---@param key string
---@param cwd string
---@param entry ai.OpencodeEntry?
---@return integer? port nil when every slot is taken by another project
local function resolve_port(key, cwd, entry)
  local persisted = tonumber(entry and entry.port)
  if persisted then
    local dir = probe(persisted, cwd)
    if not dir or same_project(dir, key, cwd) then
      return persisted
    end
  end

  local candidate = hash_port(key)
  for offset = 0, OC_PORT_SLOTS - 1 do
    local port = candidate + offset
    if port <= OC_PORT_MAX then
      local dir = probe(port, cwd)
      if not dir or same_project(dir, key, cwd) then
        return port
      end
    end
  end
  return nil
end

---@return "tmux"|"herdr"|"snacks"
local function mux_kind()
  if vim.env.TMUX ~= nil and vim.env.TMUX ~= "" and vim.fn.executable("tmux") == 1 then
    return "tmux"
  end
  if vim.env.HERDR_PANE_ID ~= nil and vim.env.HERDR_PANE_ID ~= "" and vim.fn.executable("herdr") == 1 then
    return "herdr"
  end
  return "snacks"
end

---Does the recorded multiplexer split still exist?
---@param kind string?
---@param pane string?
---@return boolean
local function pane_alive(kind, pane)
  if type(pane) ~= "string" or pane == "" then
    return false
  end
  if kind == "tmux" then
    local ok, panes = pcall(vim.fn.systemlist, { "tmux", "list-panes", "-a", "-F", "#{pane_id}" })
    return ok and type(panes) == "table" and vim.tbl_contains(vim.tbl_map(vim.trim, panes), pane)
  end
  if kind == "herdr" then
    local ok = pcall(vim.fn.system, { "herdr", "pane", "get", pane })
    return ok and vim.v.shell_error == 0
  end
  return false
end

---Herdr wraps replies in `{ id, result }`, so a pane id can land at any depth.
---@param value any
---@return string?
local function extract_pane_id(value)
  if type(value) ~= "table" then
    return nil
  end
  if type(value.pane_id) == "string" or type(value.pane_id) == "number" then
    return tostring(value.pane_id)
  end
  for _, item in pairs(value) do
    local found = extract_pane_id(item)
    if found and found ~= "" then
      return found
    end
  end
  return nil
end

---Same walk as `extract_pane_id`, for a sibling string field.
---@param value any
---@param field string
---@return string?
local function extract_field(value, field)
  if type(value) ~= "table" then
    return nil
  end
  if type(value[field]) == "string" and value[field] ~= "" then
    return value[field]
  end
  for _, item in pairs(value) do
    local found = extract_field(item, field)
    if found then
      return found
    end
  end
  return nil
end

---Run a herdr command and return its decoded JSON body, or nil when it fails.
---@param cmd string[]
---@return table?
local function herdr_json(cmd)
  local ok, out = pcall(vim.fn.system, cmd)
  if not ok or type(out) ~= "string" or vim.trim(out) == "" then
    return nil
  end
  local decoded_ok, decoded = pcall(vim.json.decode, out)
  return (decoded_ok and type(decoded) == "table") and decoded or nil
end

---@param text string
---@return string?
local function pane_id_in(text)
  local ok, decoded = pcall(vim.json.decode, text)
  return (ok and extract_pane_id(decoded)) or nil
end

---Focus this project's opencode pane.
---
---Tmux addresses panes absolutely. Herdr cannot: `pane focus` only moves to a
---*neighbour* of a source pane, so we re-issue the split we originally made — "the
---right neighbour of the pane we split from" — which lands on the TUI no matter
---where the user currently sits in the layout.
---@param entry ai.OpencodeEntry
local function focus_pane(entry)
  local pane = entry.pane
  if type(pane) ~= "string" or pane == "" then
    return
  end
  if entry.mux == "tmux" then
    pcall(vim.fn.system, { "tmux", "select-pane", "-t", pane })
    return
  end
  if entry.mux ~= "herdr" then
    return
  end

  local src = (type(entry.src) == "string" and entry.src ~= "") and entry.src
    or (vim.env.HERDR_PANE_ID ~= nil and vim.env.HERDR_PANE_ID ~= "" and vim.env.HERDR_PANE_ID)
    or nil
  local dir = (type(entry.dir) == "string" and entry.dir ~= "") and entry.dir or "right"
  if src == nil then
    notify("no herdr source pane recorded to focus opencode pane " .. pane, vim.log.levels.WARN)
    return
  end

  local function attempt()
    local body = herdr_json({ "herdr", "pane", "focus", "--direction", dir, "--pane", src })
    return body and extract_field(body, "focused_pane_id") or nil
  end

  if attempt() == pane then
    return
  end

  -- The layout moved under us (resplit, zoom, tab switch): focus the TUI's tab so the
  -- source pane has the right neighbour again, then try once more.
  local target = herdr_json({ "herdr", "pane", "get", pane })
  local tab = target and extract_field(target, "tab_id") or nil
  if tab then
    pcall(vim.fn.system, { "herdr", "tab", "focus", tab })
  end
  if attempt() == pane then
    return
  end
  notify(
    "could not focus opencode pane " .. pane .. " (herdr layout changed; src=" .. tostring(src) .. ")",
    vim.log.levels.WARN
  )
end

---Run a multiplexer command detached so the split it creates outlives this mapping.
---@param cmd string[]
---@param entry ai.OpencodeEntry
---@param capture boolean? record the pane id the command prints (tmux bare, herdr as JSON)
---@return boolean started
local function detach(cmd, entry, capture)
  return (
    pcall(vim.fn.jobstart, cmd, {
      detach = true,
      stdout_buffered = true,
      on_stdout = function(_, lines)
        if not capture then
          return
        end
        for _, line in ipairs(lines or {}) do
          local text = vim.trim(line or "")
          local id = text ~= "" and (pane_id_in(text) or text:match("^%%%d+$")) or nil
          if id then
            entry.pane = id
          end
        end
      end,
    })
  )
end

---Start this project's opencode TUI in a multiplexer split, degrading to a Snacks
---terminal split when no multiplexer CLI is usable.
---@param entry ai.OpencodeEntry
---@param cwd string
---@param extra? string[] extra CLI args appended after `--port <n>`
---@return boolean started
local function spawn_tui(entry, cwd, extra)
  -- The TUI *is* the server, so every extra arg has to survive in each backend's argv.
  local argv = { "opencode", "--port", tostring(entry.port) }
  vim.list_extend(argv, extra or {})
  entry.pane = ""

  if entry.mux == "tmux" then
    local ok, current = pcall(vim.fn.system, { "tmux", "display-message", "-p", "#{pane_id}" })
    local target = ok and vim.trim(current) or ""
    if target ~= "" then
      return detach({ "tmux", "split-window", "-h", "-c", cwd, "-t", target, "--", unpack(argv) }, entry, true)
    end
  elseif entry.mux == "herdr" then
    -- Record the pane we split from: herdr can only focus a *neighbour* of a source
    -- pane, so that pair is what makes `<leader>ot`-style refocusing reproducible.
    local current = herdr_json({ "herdr", "pane", "current", "--current" })
    local src = current and extract_field(current, "pane_id") or nil
    local dir = "right"
    entry.src, entry.dir = src, dir

    -- `herdr pane split` takes no command argument, so the TUI is a follow-up `pane run`.
    local split_cmd = { "herdr", "pane", "split" }
    if src then
      table.insert(split_cmd, "--pane")
      table.insert(split_cmd, src)
    else
      table.insert(split_cmd, "--current")
    end
    vim.list_extend(split_cmd, { "--direction", dir, "--cwd", cwd, "--no-focus" })
    local split = detach(split_cmd, entry, true)
    local ready = split
      and vim.wait(10000, function()
        return entry.pane ~= "" and pane_alive("herdr", entry.pane)
      end, 100)
    if ready then
      return detach({ "herdr", "pane", "run", entry.pane, unpack(argv) }, entry)
    end
  end

  entry.mux = "snacks"
  local ok, terminal = pcall(require, "snacks.terminal")
  if not ok then
    return false
  end
  return (pcall(terminal.open, argv, { cwd = cwd, win = { position = "right" } }))
end

---Point the plugin at `url`. `opencode.config` memoises its merged opts on first
---require, so the cached table has to move together with the global.
---@param url string
---@return string url
local function adopt(url)
  vim.g.opencode_opts = vim.tbl_deep_extend("force", vim.g.opencode_opts or {}, { server = { url = url } })

  local ok, config = pcall(require, "opencode.config")
  if not ok or type(config.opts) ~= "table" then
    return url
  end
  config.opts.server = config.opts.server or {}
  config.opts.server.url = url

  local cached_ok, connected = pcall(function()
    return require("opencode.server").connected
  end)
  if cached_ok and connected and connected.url ~= url then
    pcall(function()
      connected:disconnect()
    end)
  end
  return url
end

---Resolve this project's opencode server and point the plugin at it, reusing an
---existing split or server rather than spawning a duplicate.
---
---One server per project is mandatory: opencode 1.18 writes no `service.json` (so the
---plugin's own discovery can never succeed) and `/api/event` is global and ignores
---`x-opencode-directory`, so a shared server bleeds permission prompts between projects.
---@return string? url nil when no server could be resolved
local function ensure_opencode()
  local key, cwd = project()
  local state = read_state()
  local entry = type(state[key]) == "table" and state[key] or {}
  entry.mux, entry.pane = entry.mux or "snacks", entry.pane or ""

  -- A live pane is not proof of a live server: the pane outlives its opencode child when
  -- opencode crashes or the user quits it, leaving a shell behind that answers no probe.
  -- Trust the recorded pane only once the recorded port actually answers.
  if pane_alive(entry.mux, entry.pane) then
    local recorded = tonumber(entry.port)
    if recorded and probe(recorded, cwd) then
      focus_pane(entry)
      entry.port, entry.url = recorded, oc_url(recorded)
      return adopt(entry.url)
    end

    -- Stale pane: forget it so a fresh TUI is spawned instead of a second one.
    entry.pane = ""
  end

  local port = resolve_port(key, cwd, entry)
  if not port then
    local candidate = hash_port(key)
    notify(
      "no free port for " .. key .. " in " .. candidate .. "-" .. (candidate + OC_PORT_SLOTS - 1),
      vim.log.levels.ERROR
    )
    return nil
  end
  entry.port = port

  -- A server already answering here is adopted as-is; a second TUI would race it.
  if not probe(port, cwd) then
    entry.mux = mux_kind()
    if not spawn_tui(entry, cwd) then
      notify("could not start an opencode TUI for " .. key, vim.log.levels.ERROR)
      return nil
    end
    if not vim.wait(15000, function()
      return probe(port, cwd) ~= nil
    end, 300) then
      notify("no opencode server answered on port " .. port, vim.log.levels.ERROR)
      return nil
    end
  end

  entry.url = oc_url(port)
  state[key] = entry
  write_state(state)
  return adopt(entry.url)
end

local M = {}

---Restart the opencode child inside a pane recorded in *our* state file: the child is
---terminated first so the replacement can bind the freed port. Manually started
---opencode instances have no entry here and are never touched.
---@param entry ai.OpencodeEntry
---@param cwd string
---@param args string[] extra CLI args appended after `--port <n>`
---@return boolean restarted
local function restart_pane(entry, cwd, args)
  local argv = { "opencode", "--port", tostring(entry.port) }
  vim.list_extend(argv, args)
  local line = table.concat(argv, " ")

  if entry.mux == "tmux" then
    -- `-k` kills the current child, so the fresh one can take the port back.
    local ok = pcall(vim.fn.system, { "tmux", "respawn-pane", "-k", "-t", entry.pane, "-c", cwd, line })
    return ok and vim.v.shell_error == 0
  end

  if entry.mux == "herdr" then
    -- herdr has no respawn: interrupt the child, wait for the port to actually free
    -- up, and only then type the replacement command into the pane's shell.
    pcall(vim.fn.system, { "herdr", "pane", "send-keys", entry.pane, "ctrl+c" })
    if not vim.wait(3000, function()
      return probe(entry.port, cwd) == nil
    end, 100) then
      return false
    end
    return (pcall(vim.fn.system, { "herdr", "pane", "run", entry.pane, unpack(argv) }))
  end

  if entry.mux == "snacks" then
    local ok, terminal = pcall(require, "snacks.terminal")
    if not ok then
      return false
    end
    local term = terminal.get(argv, { cwd = cwd, win = { position = "right" } })
    if not term then
      return false
    end
    pcall(term.send_keys, term, "C-c")
    if not vim.wait(3000, function()
      return probe(entry.port, cwd) == nil
    end, 100) then
      return false
    end
    pcall(term.send_keys, term, line, "enter")
    return true
  end

  return false
end

---The fork is created by the CLI, not by an endpoint, so it is confirmed by watching
---the project session list for the new `<title> (fork #n)` root.
---@param port integer
---@param key string
---@param session_id string
---@return string? new_id
local function find_fork(port, key, session_id)
  local dir = vim.uri_encode(realpath(key))
  local ok, reply = pcall(vim.fn.system, {
    "curl",
    "-s",
    "-m",
    "2",
    "-H",
    "x-opencode-directory: " .. dir,
    "http://" .. OC_HOST .. ":" .. port .. "/api/session?directory=" .. dir .. "&order=desc&parentID=null",
  })
  if not ok or type(reply) ~= "string" or vim.trim(reply) == "" then
    return nil
  end
  local decoded_ok, decoded = pcall(vim.json.decode, reply)
  local list = decoded_ok and type(decoded) == "table" and (decoded.data or decoded)
  if type(list) ~= "table" then
    return nil
  end
  for _, session in ipairs(list) do
    if
      type(session) == "table"
      and type(session.id) == "string"
      and session.id ~= session_id
      and type(session.title) == "string"
      and session.title:find("(fork #", 1, true)
    then
      return session.id
    end
  end
  return nil
end

---Restore a session into this project's opencode as a *fork*.
---
---`-s <id>` alone would leave the newer session as the plugin's target, and `--fork`
---is the only way to branch a session (there is no HTTP fork endpoint), so the fork
---becomes the newest root session and `:Opencode`/`ask` follow it.
---@param session_id string
---@return boolean restored
function M.restore_session(session_id)
  session_id = vim.trim(session_id or "")
  if not session_id:match("^ses_%w+$") then
    notify("not an opencode session id: `" .. session_id .. "` (expected `ses_...`)", vim.log.levels.ERROR)
    return false
  end

  local key, cwd = project()
  local state = read_state()
  local recorded = type(state[key]) == "table" and state[key] or nil
  local entry = recorded or {}
  -- Only an entry this plugin wrote proves we started a server, and a Snacks terminal
  -- has no pane id to check — so an entry we cannot tie to a pane is never ours.
  local recorded_mux = recorded and recorded.mux or nil
  entry.mux, entry.pane = entry.mux or "snacks", entry.pane or ""

  local port = resolve_port(key, cwd, entry)
  if not port then
    notify("no free port for " .. key, vim.log.levels.ERROR)
    return false
  end
  entry.port = port

  local args = { "-s", session_id, "--fork" }
  local live = probe(port, cwd) ~= nil
  local owned = pane_alive(entry.mux, entry.pane) or (recorded_mux == "snacks" and live)

  if owned then
    notify("reloading this project's opencode from " .. session_id .. "…")
    if not restart_pane(entry, cwd, args) then
      notify("could not restart the opencode in " .. entry.mux .. " pane " .. entry.pane, vim.log.levels.ERROR)
      return false
    end
  elseif live then
    -- A server we did not start: never kill it, just say what to run.
    notify(
      "opencode for "
        .. key
        .. " is already running on port "
        .. port
        .. " but it was not started here.\nRun this in a split to fork the session:\n  opencode --port "
        .. port
        .. " -s "
        .. session_id
        .. " --fork",
      vim.log.levels.WARN
    )
    return false
  else
    entry.mux = mux_kind()
    if not spawn_tui(entry, cwd, args) then
      notify("could not start an opencode TUI for " .. key, vim.log.levels.ERROR)
      return false
    end
  end

  if not vim.wait(20000, function()
    return probe(port, cwd) ~= nil
  end, 300) then
    notify("no opencode server answered on port " .. port, vim.log.levels.ERROR)
    return false
  end

  entry.url = oc_url(port)
  state[key] = entry
  write_state(state)
  adopt(entry.url)

  -- `vim.wait` only reports whether the callback returned truthy, so the id is captured
  -- from the closure instead of from its result.
  local forked
  vim.wait(5000, function()
    forked = find_fork(port, key, session_id)
    return forked ~= nil
  end, 250)

  if type(forked) == "string" then
    notify("forked " .. session_id .. " as " .. forked)
    return true
  end

  notify("opencode is running, but no fork of " .. session_id .. " showed up in the session list", vim.log.levels.WARN)
  return true
end

---@param ms number?
---@return string
local function rel_time(ms)
  if type(ms) ~= "number" then
    return ""
  end
  -- `updated` is epoch milliseconds. `uv.now()` is monotonic (it tracks `hrtime()`),
  -- so only `os.time()` can be differenced against a wall-clock stamp.
  local secs = math.max(0, math.floor(os.time() - ms / 1000))
  if secs < 60 then
    return secs .. "s ago"
  end
  local mins = math.floor(secs / 60)
  if mins < 60 then
    return mins .. "m ago"
  end
  local hours = math.floor(mins / 60)
  if hours < 24 then
    return hours .. "h ago"
  end
  return math.floor(hours / 24) .. "d ago"
end

---List recent sessions for this project without blocking the editor: `opencode session
---list` is a CLI call and must never sit on the main loop.
---@param cwd string
---@param cb fun(sessions: table[]?)
local function fetch_sessions(cwd, cb)
  local chunks = {}
  local job = vim.fn.jobstart({ "opencode", "session", "list", "--format", "json", "-n", "50" }, {
    cwd = cwd,
    stdout_buffered = true,
    on_stdout = function(_, lines)
      chunks = lines
    end,
    on_exit = function(_, code)
      if code ~= 0 or type(chunks) ~= "table" or vim.trim(table.concat(chunks, "")) == "" then
        return cb(nil)
      end
      local ok, decoded = pcall(vim.json.decode, table.concat(chunks, ""))
      cb(ok and type(decoded) == "table" and decoded or nil)
    end,
  })
  if job <= 0 then
    cb(nil)
  end
end

---Session ids for `:OpencodeRestore` completion.
---@param lead string
---@return string[]
function M.complete_session(lead)
  local _, cwd = project()
  -- `vim.fn.system` takes no cwd and `jobstart` cannot answer completion synchronously.
  local ok, result = pcall(function()
    return vim
      .system({ "opencode", "session", "list", "--format", "json", "-n", "50" }, { cwd = cwd, text = true })
      :wait(3000)
  end)
  if not ok or type(result) ~= "table" or result.code ~= 0 or type(result.stdout) ~= "string" then
    return {}
  end
  local decoded_ok, decoded = pcall(vim.json.decode, result.stdout)
  if not decoded_ok or type(decoded) ~= "table" then
    return {}
  end
  local ids = {}
  for _, session in ipairs(decoded) do
    if type(session) == "table" and type(session.id) == "string" and vim.startswith(session.id, lead) then
      ids[#ids + 1] = session.id
    end
  end
  return ids
end

---Pick one of this project's recent sessions and fork it.
function M.pick_session()
  local key, cwd = project()
  fetch_sessions(cwd, function(sessions)
    if not sessions then
      notify("could not list opencode sessions — try `opencode session list --format json`", vim.log.levels.WARN)
      return
    end

    -- The payload carries each session's directory, so scope the picker to the project
    -- the same way the server scopes it.
    local items = {}
    for _, session in ipairs(sessions) do
      if type(session) == "table" and same_project(session.directory, key, cwd) then
        items[#items + 1] = {
          id = session.id,
          text = (session.title or session.id) .. "  ·  " .. rel_time(session.updated),
        }
      end
    end
    if #items == 0 then
      notify("no opencode sessions for " .. key, vim.log.levels.WARN)
      return
    end

    local ok, Picker = pcall(require, "snacks.picker")
    if not ok then
      notify("snacks.picker is unavailable", vim.log.levels.ERROR)
      return
    end
    -- `Snacks.picker.pick`'s first argument is a *source name*, so items have to ride
    -- along in `opts.items`; passing the list first would land it in `opts.source`.
    Picker.pick({
      items = items,
      title = "Opencode sessions — " .. key,
      format = "text",
      layout = { preset = "select" },
      confirm = function(picker, item)
        picker:close()
        M.restore_session(item.id)
      end,
    })
  end)
end

return {
  {
    "Exafunction/windsurf.nvim",
    enabled = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      require("codeium").setup({
        enable_cmp_source = false,
      })
    end,
  },
  -- TODO: test NeoCodeium, alternative compared to windsurf official plugin
  -- {
  --   "monkoose/neocodeium",
  --   event = "VeryLazy",
  --   config = function()
  --     local neocodeium = require("neocodeium")
  --     neocodeium.setup()
  --     vim.keymap.set("i", "<A-f>", neocodeium.accept)
  --   end,
  -- },
  -- Sidekick AI
  -- {
  --   "folke/sidekick.nvim",
  --   opts = {
  --     nes = {
  --       diff = { inline = "words" }, -- Granular diff view
  --     },
  --     cli = {
  --       mux = {
  --         backend = "tmux",
  --         enabled = true,
  --       },
  --     },
  --   },
  --   keys = {
  --     {
  --       "<Tab>",
  --       function()
  --         return require("sidekick").nes_jump_or_apply() and "" or "<Tab>"
  --       end,
  --       expr = true,
  --       desc = "NES Jump/Apply",
  --     },
  --     {
  --       "<leader>aa",
  --       function()
  --         require("sidekick.cli").toggle()
  --       end,
  --       desc = "Toggle CLI",
  --     },
  --     {
  --       "<leader>as",
  --       function()
  --         require("sidekick.cli").select()
  --       end,
  --       desc = "Select Tool",
  --     },
  --     {
  --       "<leader>ap",
  --       function()
  --         require("sidekick.cli").prompt()
  --       end,
  --       mode = { "n", "x" },
  --       desc = "Send Prompt",
  --     },
  --   },
  -- },
  {
    -- Opencode.nvim (https://github.com/nickjvandyke/opencode.nvim)
    "NickvanDyke/opencode.nvim",
    enabled = true,
    dependencies = {
      -- Recommended for `ask()` and `select()`.
      -- Required for the Snacks terminal fallback and `<leader>ot`.
      { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
    },
    -- Registered eagerly by lazy.nvim so `:OpencodeRestore` and its completion work
    -- before the plugin is loaded; `config()` creates the real command below.
    cmd = { "OpencodeRestore" },
    config = function()
      -- Probe only: the TUI is started lazily by `ensure_opencode()`, not at startup.
      local key, cwd = project()
      local port = resolve_port(key, cwd, read_state()[key])

      ---@type opencode.Opts
      vim.g.opencode_opts = {
        server = {
          url = port and oc_url(port) or nil,
          -- Normally unreachable, since a configured `url` makes discovery
          -- authoritative. Kept so `vsplit term://opencode` can never run.
          start = function()
            pcall(ensure_opencode)
          end,
        },
      }

      vim.api.nvim_create_user_command("OpencodeRestore", function(args)
        M.restore_session(args.args)
      end, {
        nargs = 1,
        desc = "Fork an opencode session into this project's TUI",
        complete = M.complete_session,
      })

      -- Required for `opts.auto_reload`.
      vim.o.autoread = true
    end,

    keys = {
      {
        "<leader>ot",
        function()
          local key, cwd = project()
          local entry = read_state()[key]
          entry = type(entry) == "table" and entry or {}
          if pane_alive(entry.mux, entry.pane) then
            ensure_opencode()
            return
          end

          local port = resolve_port(key, cwd, entry)
          local terminal_ok, terminal = pcall(require, "snacks.terminal")
          if not port or not terminal_ok then
            notify("no opencode terminal available for " .. key, vim.log.levels.ERROR)
            return
          end
          pcall(terminal.toggle, { "opencode", "--port", tostring(port) }, { cwd = cwd, win = { position = "right" } })
        end,
        desc = "Toggle opencode TUI",
      },
      {
        "<leader>oa",
        function()
          if ensure_opencode() then
            require("opencode").ask("@cursor: ")
          end
        end,
        desc = "Ask opencode",
        mode = "n",
      },
      {
        "<leader>oa",
        function()
          if ensure_opencode() then
            require("opencode").ask("@selection: ")
          end
        end,
        desc = "Ask opencode about selection",
        mode = "v",
      },
      {
        "<leader>op",
        function()
          if ensure_opencode() then
            require("opencode").select()
          end
        end,
        desc = "Select prompt",
        mode = { "n", "v" },
      },
      {
        "<leader>on",
        function()
          if ensure_opencode() then
            require("opencode").command("session_new")
          end
        end,
        desc = "New session",
      },
      {
        "<leader>os",
        function()
          M.pick_session()
        end,
        desc = "Pick opencode session",
      },
      {
        "<leader>oy",
        function()
          if ensure_opencode() then
            require("opencode").command("messages_copy")
          end
        end,
        desc = "Copy last message",
      },
      {
        "<S-C-u>",
        function()
          if ensure_opencode() then
            require("opencode").command("messages_half_page_up")
          end
        end,
        desc = "Scroll messages up",
      },
      {
        "<S-C-d>",
        function()
          if ensure_opencode() then
            require("opencode").command("messages_half_page_down")
          end
        end,
        desc = "Scroll messages down",
      },
    },
  },
}
