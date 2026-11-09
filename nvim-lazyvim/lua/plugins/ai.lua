-- 🤖 AI: AI-assisted coding and LLM integrations

local OC_HOST = "127.0.0.1"
local OC_PORT_MIN, OC_PORT_MAX = 4100, 4999
local OC_PORT_SLOTS = 20
local OC_STATE_PATH = vim.fs.joinpath(vim.fn.stdpath("state"), "opencode-servers.json")
-- LuaJIT keeps `unpack` global and only sets `table.unpack` under 5.2 compatibility.
local unpack = unpack or table.unpack

---@class ai.OpencodeEntry
---@field port? integer
---@field password? string basic-auth password printed by our `opencode serve`
---@field server_pid? integer pid of our detached `opencode serve` (survives nvim)
---@field mux? "rex"|"tmux"|"herdr"|"snacks"
---@field pane? string rex: block ID of the TUI split
---@field src? string herdr only: the pane the TUI was split from
---@field dir? string herdr only: the direction it was split in
---@field rex_session? string rex only: session the TUI block belongs to
---@field rex_source? string rex only: anchor block the TUI split was created beside
---@field rex_split? string rex only: split direction ("right")
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

---Ask a port which project it serves, authenticating with the entry's password.
---A server that rejects our credentials still proves something is listening there,
---so `listening` is true for foreign servers too — only `dir` is ours to adopt.
---@param entry ai.OpencodeEntry
---@param cwd string
---@return string? dir the served directory, when the server authenticates us
---@return boolean listening true when anything answers the port
local function probe(entry, cwd)
  local port = tonumber(entry.port)
  if not port then
    return nil, false
  end
  local cmd = { "curl", "-s", "-m", "2", "-w", "\n%{http_code}" }
  if type(entry.password) == "string" and entry.password ~= "" then
    vim.list_extend(cmd, { "-u", "opencode:" .. entry.password })
  end
  vim.list_extend(cmd, {
    "-H",
    "x-opencode-directory: " .. vim.uri_encode(cwd),
    oc_url(port) .. "/api/command",
  })
  local ok, reply = pcall(vim.fn.system, cmd)
  if not ok or type(reply) ~= "string" then
    return nil, false
  end
  local body, code = reply:match("^(.*)\n(%d%d%d)$")
  if not body or code == "000" then
    return nil, false
  end
  if code ~= "200" then
    -- 401 etc.: something is listening, but it is not ours to adopt.
    return nil, true
  end
  local decoded_ok, decoded = pcall(vim.json.decode, body)
  local location = decoded_ok and type(decoded) == "table" and decoded.location
  local dir = type(location) == "table" and location.directory
  return type(dir) == "string" and dir ~= "" and dir or nil, true
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

---Persisted port first while it still serves this project (or is free), else the
---first free (or self-serving) slot in the window starting at the hashed candidate.
---@param key string
---@param cwd string
---@param entry ai.OpencodeEntry?
---@return integer? port nil when every slot is taken by another project
local function resolve_port(key, cwd, entry)
  local persisted = tonumber(entry and entry.port)
  if persisted then
    local dir, listening = probe(entry, cwd)
    if not listening or (dir and same_project(dir, key, cwd)) then
      return persisted
    end
  end

  local candidate = hash_port(key)
  for offset = 0, OC_PORT_SLOTS - 1 do
    local port = candidate + offset
    if port <= OC_PORT_MAX then
      -- No password for unknown candidates: a 401 still means "occupied, skip".
      local dir, listening = probe({ port = port }, cwd)
      if not listening or (dir and same_project(dir, key, cwd)) then
        return port
      end
    end
  end
  return nil
end

---Resolve and record this project's port. Credentials and pid belong to the old
---port's server, so a changed port invalidates them.
---@param key string
---@param cwd string
---@param entry ai.OpencodeEntry
---@return integer? port nil when every slot is taken by another project
local function assign_port(key, cwd, entry)
  local port = resolve_port(key, cwd, entry)
  if not port then
    return nil
  end
  if port ~= tonumber(entry.port) then
    entry.password, entry.server_pid = nil, nil
  end
  entry.port = port
  return port
end

---Rex exports both IDs into every process running in one of its blocks. Treat that
---pair as authoritative: it is an explicit "run inside Rex" contract, unlike the
---incidental tmux/herdr variables a Rex session may also inherit.
---@return string? session
---@return string? block
local function rex_env()
  local session, block = vim.env.REX_SESSION, vim.env.REX_BLOCK
  if
    type(session) == "string"
    and session ~= ""
    and type(block) == "string"
    and block ~= ""
    and vim.fn.executable("rex") == 1
  then
    return session, block
  end
end

---@return "rex"|"tmux"|"herdr"|"snacks"
local function mux_kind()
  if rex_env() then
    return "rex"
  end
  if vim.env.TMUX ~= nil and vim.env.TMUX ~= "" and vim.fn.executable("tmux") == 1 then
    return "tmux"
  end
  if vim.env.HERDR_PANE_ID ~= nil and vim.env.HERDR_PANE_ID ~= "" and vim.fn.executable("herdr") == 1 then
    return "herdr"
  end
  return "snacks"
end

---Inside Rex, all OpenCode UI must live in Rex. Retarget an entry recorded from
---another multiplexer by dropping its pane id; that backend's pane/session is left
---untouched. Returns false when this nvim is not running inside Rex.
---@param entry ai.OpencodeEntry
---@return boolean in_rex
local function prefer_rex(entry)
  local session, block = rex_env()
  if not session then
    return false
  end
  if entry.mux ~= "rex" or entry.rex_session ~= session then
    entry.mux, entry.pane = "rex", ""
    entry.rex_source = nil
  end
  entry.rex_session, entry.rex_split = session, "right"
  entry.rex_source = entry.rex_source or block
  return true
end

---Does the recorded multiplexer split still exist?
---@param kind string?
---@param pane string?
---@param session? string rex only: session to scope the block lookup to
---@return boolean
local function pane_alive(kind, pane, session)
  if type(pane) ~= "string" or pane == "" then
    return false
  end
  if kind == "rex" then
    local scope = session
    if type(scope) ~= "string" or scope == "" then
      scope = vim.env.REX_SESSION
    end
    if type(scope) ~= "string" or scope == "" then
      return false
    end
    local ok, out = pcall(vim.fn.system, { "rex", "block", "ls", "-s", scope, "--json" })
    if not ok or type(out) ~= "string" or vim.trim(out) == "" or vim.v.shell_error ~= 0 then
      return false
    end
    local decoded_ok, decoded = pcall(vim.json.decode, out)
    local blocks = decoded_ok and type(decoded) == "table" and decoded.blocks
    if type(blocks) ~= "table" then
      return false
    end
    for _, block in ipairs(blocks) do
      if type(block) == "table" and block.block_id == pane then
        return true
      end
    end
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

---First still-live Rex block among the candidates, or nil when none survive.
---@param session string
---@param ... string? preferred first
---@return string?
local function rex_anchor(session, ...)
  for i = 1, select("#", ...) do
    local block = select(i, ...)
    if type(block) == "string" and block ~= "" and pane_alive("rex", block, session) then
      return block
    end
  end
  return nil
end

---One shell command line for argv. Rex types the text into the block's shell, so
---every token is quoted; passwords and paths are data, not shell syntax.
---@param argv string[]
---@return string
local function shell_line(argv)
  local parts = {}
  for _, token in ipairs(argv) do
    parts[#parts + 1] = vim.fn.shellescape(token)
  end
  return table.concat(parts, " ")
end

---Decoded `rex block call ... process` reply, or nil when the block is gone.
---@param session string
---@param block string
---@return table?
local function rex_process(session, block)
  local ok, out = pcall(vim.fn.system, { "rex", "block", "call", "-s", session, "-b", block, "process" })
  if not ok or type(out) ~= "string" or vim.trim(out) == "" or vim.v.shell_error ~= 0 then
    return nil
  end
  local decoded_ok, decoded = pcall(vim.json.decode, out)
  return (decoded_ok and type(decoded) == "table") and decoded or nil
end

---@param value any
---@return string?
local function basename(value)
  if type(value) ~= "string" or value == "" then
    return nil
  end
  return value:match("([^/]+)$") or value
end

---Is this foreground process the OpenCode TUI? Process metadata is authoritative;
---terminal text is not. The v2 TUI's `foreground` reports name/path/argv0
---`opencode`, while a block back at a prompt reports its shell (fish/zsh/login).
---@param fg table?
---@return boolean
local function fg_is_opencode(fg)
  if type(fg) ~= "table" then
    return false
  end
  return fg.name == "opencode" or basename(fg.path) == "opencode" or basename(fg.argv0) == "opencode"
end

---Login shells are commonly reported as `-fish`/`-zsh` in argv0.
---@param value any
---@return string?
local function process_name(value)
  local name = basename(value)
  if name and name:sub(1, 1) == "-" then
    return name:sub(2)
  end
  return name
end

---Interactive shells we may safely type into. `login` is what Rex reports before
---the login shell has exec'd, so it counts as a prompt too.
local SHELL_NAMES = {
  login = true,
  fish = true,
  zsh = true,
  bash = true,
  sh = true,
  dash = true,
  ash = true,
  ksh = true,
  mksh = true,
  yash = true,
  tcsh = true,
  csh = true,
  nu = true,
  nushell = true,
  pwsh = true,
  powershell = true,
  xonsh = true,
  elvish = true,
  ion = true,
}

---Is this foreground process a known interactive shell prompt? Anything else
---(nvim, top, a pager, ...) must never receive typed text.
---@param fg table?
---@return boolean
local function fg_is_shell(fg)
  if type(fg) ~= "table" then
    return false
  end
  for _, value in ipairs({ fg.name, fg.path, fg.argv0 }) do
    local name = process_name(value)
    if name and SHELL_NAMES[name] then
      return true
    end
  end
  return false
end

---Classify what currently owns the recorded block's foreground. `nil` means the
---block or its process metadata is unavailable, which is never safe to type into.
---@param entry ai.OpencodeEntry
---@param session string?
---@return "tui"|"shell"|"other"|nil
local function rex_block_state(entry, session)
  if type(session) ~= "string" or session == "" or type(entry.pane) ~= "string" or entry.pane == "" then
    return nil
  end
  local process = rex_process(session, entry.pane)
  local fg = type(process) == "table" and process.foreground
  if type(fg) ~= "table" then
    return nil
  end
  if fg_is_opencode(fg) then
    return "tui"
  end
  if fg_is_shell(fg) then
    return "shell"
  end
  return "other"
end

---A live Rex block is not a live TUI: our block is a persistent shell, so ask the
---block what currently owns the foreground.
---@param entry ai.OpencodeEntry
---@param session string?
---@return boolean
local function rex_tui_running(entry, session)
  return rex_block_state(entry, session) == "tui"
end

---Is the recorded block sitting at a recognized shell prompt?
---@param entry ai.OpencodeEntry
---@param session string?
---@return boolean
local function rex_shell_ready(entry, session)
  return rex_block_state(entry, session) == "shell"
end

---Create a persistent Rex shell block and record its ID. No command is attached:
---the block stays at a prompt after the TUI exits, ready for the next launch.
---@param entry ai.OpencodeEntry
---@param cwd string
---@param session string
---@param anchor string? block to split beside; nil splits the focused block
---@param focus? boolean focus the new block (default true)
---@return boolean created
local function rex_shell_split(entry, cwd, session, anchor, focus)
  local cmd = { "rex", "split", "-s", session }
  if anchor then
    vim.list_extend(cmd, { "-b", anchor })
  end
  vim.list_extend(cmd, { "--split=" .. (entry.rex_split or "right"), "-c", cwd })
  if focus == false then
    cmd[#cmd + 1] = "--focus=false"
  end
  cmd[#cmd + 1] = "--json"

  local ok, out = pcall(vim.fn.system, cmd)
  if not ok or type(out) ~= "string" or vim.trim(out) == "" or vim.v.shell_error ~= 0 then
    return false
  end
  local decoded_ok, decoded = pcall(vim.json.decode, out)
  local ids = decoded_ok and type(decoded) == "table" and decoded.block_ids
  local id = type(ids) == "table" and ids[1] or nil
  if type(id) ~= "string" or id == "" then
    return false
  end
  entry.pane = id
  return true
end

---Type argv into an existing Rex shell block and run it. Used both for the first
---launch and every relaunch, so the split itself is never recreated.
---@param entry ai.OpencodeEntry
---@param session string
---@param argv string[]
---@return boolean sent
local function rex_run_in_block(entry, session, argv)
  if type(entry.pane) ~= "string" or entry.pane == "" then
    return false
  end
  local ok = pcall(vim.fn.system, { "rex", "send", "-s", session, "-b", entry.pane, shell_line(argv) })
  if not ok or vim.v.shell_error ~= 0 then
    return false
  end
  local key_ok = pcall(vim.fn.system, { "rex", "send-key", "-s", session, "-b", entry.pane, "enter" })
  return key_ok and vim.v.shell_error == 0
end

---Interrupt the TUI only when it is actually in the foreground, then wait for the
---block to return to its shell. OpenCode v2 often needs a second interrupt, so
---retry while the foreground still reports opencode (never send to a bare prompt).
---@param entry ai.OpencodeEntry
---@param session string
---@return boolean shell_ready
local function rex_stop_tui(entry, session)
  for _ = 1, 3 do
    if not rex_tui_running(entry, session) then
      return true
    end
    pcall(vim.fn.system, { "rex", "send-key", "-s", session, "-b", entry.pane, "ctrl+c" })
    if vim.wait(1500, function()
      return not rex_tui_running(entry, session)
    end, 100) then
      return true
    end
  end
  return not rex_tui_running(entry, session)
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
---Rex and tmux address panes absolutely (`rex focus` / `select-pane`). Herdr cannot:
---`pane focus` only moves to a *neighbour* of a source pane, so we re-issue the split
---we originally made — "the right neighbour of the pane we split from" — which lands
---on the TUI no matter where the user currently sits in the layout.
---@param entry ai.OpencodeEntry
local function focus_pane(entry)
  local pane = entry.pane
  if type(pane) ~= "string" or pane == "" then
    return
  end
  if entry.mux == "rex" then
    local session = (type(entry.rex_session) == "string" and entry.rex_session ~= "") and entry.rex_session
      or vim.env.REX_SESSION
    if type(session) ~= "string" or session == "" then
      notify("no rex session recorded to focus opencode block " .. pane, vim.log.levels.WARN)
      return
    end
    local ok = pcall(vim.fn.system, { "rex", "focus", "-s", session, pane })
    if not ok or vim.v.shell_error ~= 0 then
      notify("could not focus opencode block " .. pane .. " in " .. session, vim.log.levels.WARN)
    end
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

---TUI argv for this project's server. The TUI is a pure client in v2: it attaches
---with `--server <url>` and authenticates via `OPENCODE_PASSWORD` in its env
---(`env` keeps that portable across tmux/herdr/Snacks, which all exec argv).
---@param entry ai.OpencodeEntry
---@param extra? string[] extra CLI args appended after `--server <url>`
---@return string[]
local function tui_argv(entry, extra)
  local argv = { "env", "OPENCODE_PASSWORD=" .. (entry.password or ""), "opencode", "--server", oc_url(entry.port) }
  vim.list_extend(argv, extra or {})
  return argv
end

---Start `opencode serve` detached on the entry's port and capture the password it
---prints ("server password <token>" on stdout). An already-authenticating server is
---adopted instead of raced.
---@param entry ai.OpencodeEntry
---@param cwd string
---@return boolean started
local function start_server(entry, cwd)
  if probe(entry, cwd) then
    return true
  end

  -- Start the server detached, redirecting stdout/stderr to a temp file so we can
  -- capture the password. The password is printed once right after the listener binds.
  local log_file = vim.fs.joinpath(vim.fn.stdpath("cache"), "opencode_" .. entry.port .. ".log")
  local cmd = string.format("opencode serve --port %d >%s 2>&1 &", entry.port, vim.fn.shellescape(log_file))

  -- Background shell command returns immediately; ignore its exit code.
  vim.fn.system(cmd)

  -- Give the server a moment to start and write the password to the log file.
  local password ---@type string?
  local got = vim.wait(10000, function()
    local lines = vim.fn.readfile(log_file, "", 100)
    if type(lines) == "table" then
      for _, line in ipairs(lines) do
        local token = tostring(line or ""):match("server password%s+(%S+)")
        if token then
          password = token
          return true
        end
      end
    end
    return false
  end, 100)

  -- Try to get the PID from the log file or by finding the process on the port
  local pid ---@type integer?
  if password then
    -- Find the PID by checking what's listening on the port
    local lsof_out = vim.fn.systemlist({ "lsof", "-nP", "-iTCP:" .. entry.port, "-sTCP:LISTEN", "-t" })
    if type(lsof_out) == "table" and #lsof_out > 0 then
      pid = tonumber(lsof_out[1])
    end
  end

  -- Clean up log file
  pcall(vim.fn.delete, log_file)

  if not password or not pid then
    return false
  end

  entry.server_pid = pid
  entry.password = password
  return true
end

---Launch the TUI into this project's persistent Rex block, reusing it when the
---foreground is a TUI (interrupt it back to a prompt) or a recognized shell.
---Anything else — an unrelated program or unreadable metadata — is left untouched
---and gets exactly one fresh split beside the current/stored anchor.
---@param entry ai.OpencodeEntry
---@param cwd string
---@param session string
---@param argv string[]|fun():string[] command to type, or a builder run after `before_send`
---@param focus boolean
---@param known_state? "tui"|"shell"|"other"|nil precomputed foreground; nil classifies here
---@param opts? {focus_reused_only?: boolean, before_send?: fun(): boolean, run_error_prefix?: string}
---@return boolean ok
local function rex_launch(entry, cwd, session, argv, focus, known_state, opts)
  opts = opts or {}
  entry.rex_session = session
  entry.rex_split = entry.rex_split or "right"

  local state = known_state
  if state == nil then
    state = pane_alive("rex", entry.pane, session) and rex_block_state(entry, session) or nil
  end
  local reused = state == "tui" or state == "shell"

  local function fresh_split()
    -- Prefer the block this nvim runs in, so a fresh split lands beside the user's
    -- current work; the stored anchor is the fallback when the environment moved.
    local _, current = rex_env()
    local anchor = rex_anchor(session, current, entry.rex_source)
    entry.rex_source = anchor
    entry.pane = ""
    return rex_shell_split(entry, cwd, session, anchor, focus)
  end

  if not reused and not fresh_split() then
    notify("could not create a rex split for opencode", vim.log.levels.ERROR)
    return false
  end
  if state == "tui" and not rex_stop_tui(entry, session) then
    notify("could not return rex block " .. entry.pane .. " to a shell", vim.log.levels.ERROR)
    return false
  end
  -- Only type into a confirmed shell; if the interrupt left another program (or
  -- the block vanished), leave it untouched and use a fresh split.
  if reused and not rex_shell_ready(entry, session) then
    if not fresh_split() then
      notify("could not create a rex split for opencode", vim.log.levels.ERROR)
      return false
    end
    reused = false
  end

  if opts.before_send and not opts.before_send() then
    return false
  end
  local command = type(argv) == "function" and argv() or argv
  if not command then
    return false
  end
  if not rex_run_in_block(entry, session, command) then
    local prefix = opts.run_error_prefix or "could not start opencode in rex block "
    notify(prefix .. entry.pane, vim.log.levels.ERROR)
    return false
  end
  if focus and (reused or not opts.focus_reused_only) then
    focus_pane(entry)
  end
  return true
end

---Open this project's opencode TUI in a Rex/tmux/herdr split, degrading to a Snacks
---terminal split when no multiplexer CLI is usable. A detected Rex session never
---degrades to Snacks: a failed split returns false. The server must already be up.
---@param entry ai.OpencodeEntry
---@param cwd string
---@param extra? string[] extra CLI args appended after `--server <url>`
---@param focus? boolean focus/reveal the TUI (default true)
---@return boolean started
local function start_tui(entry, cwd, extra, focus)
  focus = focus ~= false
  local argv = tui_argv(entry, extra)

  if entry.mux == "rex" then
    local session = rex_env()
    session = session or (type(entry.rex_session) == "string" and entry.rex_session ~= "" and entry.rex_session) or nil
    if not session then
      notify("no rex session available to split opencode into", vim.log.levels.WARN)
      return false
    end
    return rex_launch(entry, cwd, session, argv, focus, nil, { focus_reused_only = true })
  end

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
      -- `herdr pane run` parses global flags (like --session) before the command,
      -- so send the shell-quoted line with send-text + send-keys instead.
      local cmd_line = shell_line(argv)
      pcall(vim.fn.system, { "herdr", "--session", "default", "pane", "send-text", entry.pane, cmd_line })
      pcall(vim.fn.system, { "herdr", "--session", "default", "pane", "send-keys", entry.pane, "enter" })
      return true
    end
  end

  entry.mux = "snacks"
  local ok, terminal = pcall(require, "snacks.terminal")
  if not ok then
    return false
  end
  return (pcall(terminal.open, argv, { cwd = cwd, win = { position = "right" } }))
end

---Start this project's opencode server in the background and its TUI in a
---Rex/tmux/herdr split, degrading to a Snacks terminal split when no multiplexer
---CLI is usable. A detected Rex session never degrades to Snacks.
---@param entry ai.OpencodeEntry
---@param cwd string
---@param extra? string[] extra CLI args appended after `--server <url>`
---@param focus? boolean focus/reveal the TUI (default true)
---@return boolean started
local function spawn_tui(entry, cwd, extra, focus)
  if not start_server(entry, cwd) then
    return false
  end
  return start_tui(entry, cwd, extra, focus)
end

---Point the plugin at `url`, authenticating with `password` when the server
---requires it. `opencode.config` memoises its merged opts on first require, so the
---cached table has to move together with the global.
---@param url string
---@param password? string
---@return string url
local function adopt(url, password)
  vim.g.opencode_opts =
    vim.tbl_deep_extend("force", vim.g.opencode_opts or {}, { server = { url = url, password = password } })

  local ok, config = pcall(require, "opencode.config")
  if not ok or type(config.opts) ~= "table" then
    return url
  end
  config.opts.server = config.opts.server or {}
  config.opts.server.url = url
  config.opts.server.password = password

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

---Persist this project's entry and point the plugin at it.
---@param key string
---@param state table<string, ai.OpencodeEntry>
---@param entry ai.OpencodeEntry
---@return string url
local function commit_entry(key, state, entry)
  entry.url = oc_url(entry.port)
  state[key] = entry
  write_state(state)
  return adopt(entry.url, entry.password)
end

---Resolve this project's opencode server and point the plugin at it, reusing an
---existing split or server rather than spawning a duplicate.
---
---One server per project is mandatory: opencode 1.18 writes no `service.json` (so the
---plugin's own discovery can never succeed) and `/api/event` is global and ignores
---`x-opencode-directory`, so a shared server bleeds permission prompts between projects.
---@param opts? {focus?: boolean} focus/reveal the TUI (default true)
---@return string? url nil when no server could be resolved
local function ensure_opencode(opts)
  local focus = not opts or opts.focus ~= false
  local key, cwd = project()
  local state = read_state()
  local entry = type(state[key]) == "table" and state[key] or {}
  entry.mux, entry.pane = entry.mux or "snacks", entry.pane or ""
  prefer_rex(entry)

  local session ---@type string?
  if entry.mux == "rex" then
    local detected = rex_env()
    session = (type(entry.rex_session) == "string" and entry.rex_session ~= "") and entry.rex_session or detected
    entry.rex_session = session
  end

  local recorded = tonumber(entry.port)
  local pane_up = pane_alive(entry.mux, entry.pane, entry.rex_session)
  ---@type "tui"|"shell"|"other"|nil
  local rex_state = (entry.mux == "rex" and pane_up) and rex_block_state(entry, session) or nil
  local tui_up = rex_state == "tui"
  local shell_up = rex_state == "shell"

  -- Reuse is only safe when the recorded pane is genuinely serving this project: the
  -- pane outlives its opencode child when opencode crashes or the user quits it.
  if pane_up and recorded and (entry.mux ~= "rex" or tui_up) and probe(entry, cwd) then
    if focus then
      focus_pane(entry)
    end
    entry.port = recorded
    return commit_entry(key, state, entry)
  end

  -- Rex blocks are persistent shells. If the block survived but the TUI exited,
  -- relaunch in that *same* block (fresh password/server when needed) rather than
  -- focusing a bare prompt or splitting a second pane beside Neovim.
  if entry.mux == "rex" and session and pane_up and (tui_up or shell_up) then
    local port = assign_port(key, cwd, entry)
    if not port then
      notify("no free port for " .. key, vim.log.levels.ERROR)
      return nil
    end

    local ok = rex_launch(
      entry,
      cwd,
      session,
      function()
        return tui_argv(entry)
      end,
      focus,
      rex_state,
      {
        before_send = function()
          -- A TUI may still front a server that just died: start one before typing.
          if not probe(entry, cwd) and not start_server(entry, cwd) then
            notify("could not start an opencode server for " .. key, vim.log.levels.ERROR)
            return false
          end
          return true
        end,
        run_error_prefix = "could not start an opencode TUI in rex block ",
      }
    )
    if not ok then
      return nil
    end
    return commit_entry(key, state, entry)
  end

  -- A live Rex block running something else (nvim, a pager, ...) or whose process
  -- metadata is unreadable must never receive typed text. Leave it untouched and
  -- record a fresh split instead; the old block is not closed.
  if entry.mux == "rex" and pane_up and not (tui_up or shell_up) then
    entry.pane = ""
  end

  -- Non-Rex stale pane: forget it so a fresh TUI is spawned instead of a second one.
  if pane_up and entry.mux ~= "rex" then
    entry.pane = ""
  end

  local port = assign_port(key, cwd, entry)
  if not port then
    local candidate = hash_port(key)
    notify(
      "no free port for " .. key .. " in " .. candidate .. "-" .. (candidate + OC_PORT_SLOTS - 1),
      vim.log.levels.ERROR
    )
    return nil
  end

  -- Server already answering with our credentials: adopt it.
  local server_live = probe(entry, cwd)
  if server_live then
    -- Server is up, but we need a TUI pane if we don't have one.
    if entry.pane == "" or not pane_alive(entry.mux, entry.pane, entry.rex_session) then
      entry.mux = mux_kind()
      if not start_tui(entry, cwd, nil, focus) then
        notify("could not start an opencode TUI for " .. key, vim.log.levels.ERROR)
        return nil
      end
      -- Only tmux reports its pane asynchronously after the detached split returns;
      -- herdr already waited inside start_tui and Snacks has no pane to await.
      if entry.mux == "tmux" then
        vim.wait(3000, function()
          return pane_alive(entry.mux, entry.pane, entry.rex_session)
        end, 100)
      end
    end
  else
    -- No server: start server + TUI
    entry.mux = mux_kind()
    if not spawn_tui(entry, cwd, nil, focus) then
      notify("could not start an opencode server/TUI for " .. key, vim.log.levels.ERROR)
      return nil
    end
    if not vim.wait(15000, function()
      return (probe(entry, cwd)) ~= nil
    end, 300) then
      notify("no opencode server answered on port " .. port, vim.log.levels.ERROR)
      return nil
    end
  end

  return commit_entry(key, state, entry)
end

---Resolve/start this project's detached OpenCode server without starting or
---focusing a TUI. Ask uses this so cancelling the input never leaves a blank root.
---@return boolean ready
local function ensure_server()
  local key, cwd = project()
  local state = read_state()
  local entry = type(state[key]) == "table" and state[key] or {}
  entry.mux, entry.pane = entry.mux or mux_kind(), entry.pane or ""
  prefer_rex(entry)

  local port = assign_port(key, cwd, entry)
  if not port then
    local candidate = hash_port(key)
    notify(
      "no free port for " .. key .. " in " .. candidate .. "-" .. (candidate + OC_PORT_SLOTS - 1),
      vim.log.levels.ERROR
    )
    return false
  end

  if not probe(entry, cwd) and not start_server(entry, cwd) then
    notify("could not start an opencode server for " .. key, vim.log.levels.ERROR)
    return false
  end

  commit_entry(key, state, entry)
  return true
end

local M = {}

---Resume an existing root session in this project's opencode TUI.
---
---The selected ID is passed unchanged as `--session <id>`; no fork and no child
---session is created. The detached server is a shared service, so an authenticating
---server is kept alive and only the TUI client is reopened. Rex reuses its persistent
---shell block (interrupting only a foreground TUI), so switching session never opens
---an embedded Neovim terminal/tab.
---@param session_id string
---@param opts? {focus?: boolean} focus/reveal the TUI (default true)
---@return boolean restored
function M.restore_session(session_id, opts)
  local focus = not opts or opts.focus ~= false
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
  prefer_rex(entry)

  local port = assign_port(key, cwd, entry)
  if not port then
    notify("no free port for " .. key, vim.log.levels.ERROR)
    return false
  end

  local dir, live = probe(entry, cwd)
  -- We own the server when it authenticates with our password. A Snacks entry with
  -- anything listening counts too (there is no pane to check), matching ensure_opencode.
  local owned = dir ~= nil or (recorded_mux == "snacks" and live)

  if live and not owned then
    -- A server we did not start: never stop it or mutate its sessions, just say what
    -- to run. Other clients and their active tasks stay untouched.
    notify(
      "opencode for "
        .. key
        .. " is already running on port "
        .. port
        .. " but it was not started here.\nRun this in a split to continue the session:\n  opencode --server "
        .. oc_url(port)
        .. " --session "
        .. session_id,
      vim.log.levels.WARN
    )
    return false
  end

  local args = { "--session", session_id }
  if not live then
    -- No listener at all: start the server this flow owns, then the TUI client.
    entry.mux = mux_kind()
    if not spawn_tui(entry, cwd, args, focus) then
      notify("could not start an opencode server/TUI for " .. key, vim.log.levels.ERROR)
      return false
    end
    if not vim.wait(15000, function()
      return probe(entry, cwd) ~= nil
    end, 300) then
      notify("no opencode server answered on port " .. port, vim.log.levels.ERROR)
      return false
    end
  else
    -- Keep the shared server alive: only the TUI client is reopened on the selected
    -- session. Rex reuses/relaunches its persistent block; other mux paths split anew.
    if not start_tui(entry, cwd, args, focus) then
      notify("could not open opencode in " .. entry.mux, vim.log.levels.ERROR)
      return false
    end
  end

  commit_entry(key, state, entry)
  notify("resumed " .. session_id)
  return true
end

---Ask OpenCode in a fresh root session that is created only after the input is
---submitted.
---
---This intentionally bypasses `resolve_session()` for the first prompt: the rendered
---cursor/selection context must land in the root created by this call, not whichever
---session happened to be newest before the dialog opened. The TUI is switched to that
---root without focus so the Ask input keeps the keyboard. Later plugin actions use
---normal newest-root resolution, and the new root is newest.
---@param default string
function M.ask_new_session(default)
  if not ensure_server() then
    return
  end

  local Promise = require("opencode.promise")
  local discovery = require("opencode.server.discovery")
  local Context = require("opencode.context")
  local ui = require("opencode.ui.ask")

  local context ---@type opencode.context.Context?
  local server ---@type opencode.server.Server?
  local submitted = false

  return discovery
    .get()
    :next(function(found)
      server = found
      context = Context.new(server)
      return ui.ask(default, context)
    end)
    :next(function(input)
      submitted = true
      local plaintext = context:render(input).output:plaintext()
      return server:request("/api/session", "POST", {}):next(function(response)
        local data = type(response) == "table" and response.data
        local id = type(data) == "table" and data.id
        if type(id) ~= "string" or id == "" then
          return Promise.reject("OpenCode did not return a session id")
        end
        -- Switch the persistent TUI before prompting. No focus: the Ask input owns
        -- the keyboard. `restore_session` still passes this exact id unchanged.
        if not M.restore_session(id, { focus = false }) then
          return Promise.reject("could not open opencode session " .. id)
        end
        return server:prompt(id, plaintext):next(function()
          context:clear()
        end)
      end)
    end)
    :catch(function(err)
      -- `ui.ask` already resumes on cancellation; only resume failures after submit.
      if submitted and context then
        context:resume()
      end
      notify(tostring(err), vim.log.levels.ERROR)
    end)
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

---Delete a session (and its child sessions) after an explicit confirmation.
---@param picker snacks.Picker
---@param item snacks.picker.Item
local function delete_session(picker, item)
  if type(item) ~= "table" or type(item.id) ~= "string" or item.id == "" then
    return
  end

  local ok, util = pcall(require, "snacks.picker.util")
  if not ok or type(util.confirm) ~= "function" then
    notify("cannot confirm session deletion — snacks.picker is unavailable", vim.log.levels.ERROR)
    return
  end

  local id = item.id
  local prompt = table.concat({
    "Delete opencode session " .. id .. "?",
    "",
    "This permanently removes the session history and all child sessions, including active subagents.",
    "There is no undo.",
  }, "\n")

  util.confirm(prompt, function()
    local _, cwd = project()
    local started = pcall(
      vim.system,
      { "opencode", "session", "delete", id },
      { cwd = cwd, text = true },
      function(result)
        vim.schedule(function()
          if type(result) ~= "table" or result.code ~= 0 then
            local detail = type(result) == "table" and (result.stderr or result.stdout) or ""
            detail = vim.trim(detail or "")
            notify(
              "could not delete opencode session " .. id .. (detail ~= "" and (": " .. detail) or ""),
              vim.log.levels.ERROR
            )
            return
          end
          pcall(function()
            picker:close()
          end)
          notify("deleted opencode session " .. id)
          M.pick_session()
        end)
      end
    )
    if not started then
      notify("could not delete opencode session " .. id, vim.log.levels.ERROR)
    end
  end)
end

---Pick one of this project's recent sessions and resume it in the persistent TUI.
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
      actions = {
        delete_session = delete_session,
      },
      win = {
        input = {
          keys = {
            ["<C-x>"] = { "delete_session", mode = { "n", "i" }, desc = "Delete session" },
          },
        },
        list = {
          keys = {
            ["<C-x>"] = { "delete_session", mode = { "n" }, desc = "Delete session" },
          },
        },
      },
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
        -- Blink owns completion; stop Codeium's own virtual-text requests in
        -- transient inputs (OpenCode Ask) where they only produce errors.
        virtual_text = {
          filetypes = {
            opencode_ask = false,
            snacks_input = false,
          },
        },
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
      -- Probe only: the server/TUI are started lazily by `ensure_opencode()`.
      local key, cwd = project()
      local recorded = read_state()[key]
      local entry = type(recorded) == "table" and recorded or {}
      local port = resolve_port(key, cwd, entry)

      ---@type opencode.Opts
      vim.g.opencode_opts = {
        server = {
          url = port and oc_url(port) or nil,
          password = port and entry.password or nil,
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
        desc = "Resume an opencode session in this project's TUI",
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
          local state = read_state()
          local entry = type(state[key]) == "table" and state[key] or {}
          entry.mux, entry.pane = entry.mux or "snacks", entry.pane or ""

          -- Inside Rex the split *is* the terminal. Persist the detected session so
          -- `ensure_opencode()` reuses/focuses the block instead of falling back to Snacks.
          if prefer_rex(entry) then
            state[key] = entry
            write_state(state)
            ensure_opencode()
            return
          end

          if pane_alive(entry.mux, entry.pane, entry.rex_session) then
            ensure_opencode()
            return
          end

          local port = resolve_port(key, cwd, entry)
          local terminal_ok, terminal = pcall(require, "snacks.terminal")
          if not port or not terminal_ok then
            notify("no opencode terminal available for " .. key, vim.log.levels.ERROR)
            return
          end
          entry.port = port
          -- v2's TUI is a client: the server must already be up for it to attach to.
          if not probe(entry, cwd) and not start_server(entry, cwd) then
            notify("could not start an opencode server for " .. key, vim.log.levels.ERROR)
            return
          end
          state[key] = entry
          write_state(state)
          pcall(terminal.toggle, tui_argv(entry), { cwd = cwd, win = { position = "right" } })
        end,
        desc = "Toggle opencode TUI",
      },
      {
        "<leader>oa",
        function()
          M.ask_new_session("@cursor: ")
        end,
        desc = "Ask opencode",
        mode = "n",
      },
      {
        "<leader>oa",
        function()
          M.ask_new_session("@selection: ")
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
