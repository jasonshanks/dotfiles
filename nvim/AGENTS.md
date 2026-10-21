# Agent Configuration

## Build/Lint/Test Commands
- Formatting: `stylua .` (uses stylua.toml config)
- No specific test framework used - this is a Neovim configuration repo

## Code Style Guidelines
- Language: Lua
- Indentation: 2 spaces (enforced by stylua)
- Line width: 120 characters
- Naming: snake_case for variables/functions, PascalCase for classes
- Imports: Use relative paths with `require()` for local modules
- No explicit type annotations (standard Lua)
- Error handling: Use `error()` for exceptions, check return values
- Comments: Minimal, self-documenting code preferred

## Plugin Architecture
- Uses Lazy.nvim for plugin management
- Plugin configurations in `lua/plugins/`
- Core configuration in `lua/config/`
- Personal configurations in `lua/jason/`

## Key Conventions
- Follow existing patterns in the codebase
- Prefer LazyVim's default configurations when possible
- Keep plugin configurations modular and focused
- Use `vim.notify()` for user notifications
## Opencode Integration (Critical) — v2 Architecture

The `lua/plugins/ai.lua` file contains a per-project OpenCode server manager for **OpenCode v2** (server/TUI split with basic auth).

### Server Discovery (v2)
- **Port must be pinned**: v2 has no auto-discovery. Always pass `--port <N>` to `opencode serve`.
- **Server/TUI split**: Server runs `opencode serve --port N` (detached, prints `server password <token>` to stdout). TUI runs `opencode --server http://127.0.0.1:N` with `OPENCODE_PASSWORD` env var.
- **Basic auth**: All API calls use `-u opencode:<password>`. The password is captured once at server start and persisted in state.
- **Project isolation**: `x-opencode-directory` header scopes regular API requests. Each project gets its own server on a deterministic port (hash 4100-4999).
- **Realpath keys**: State keys are the realpath of the project directory. `vim.fn.getcwd()` returns realpath; symlink forms do not match.
- **Probe truth**: `probe(entry, cwd)` calls `GET /api/command` with auth + `x-opencode-directory`. Returns `(dir, listening)` tuple — `listening=true` for foreign servers (401), `dir` non-nil only when auth succeeds. Never trust pane liveness alone.

### Sessions & Forking (v2)
- **Targeting**: `Server:resolve_session()` picks newest non-archived **root** session (`parentID=null`) for cwd, sorted by `updated`. Used by both `api/prompt.lua` and `api/command.lua`.
- **Forking is API-only**: `POST /api/session` with `{"parentID": "<id>"}` returns new child session ID. No CLI `--fork` flag in v2.
- **Fork detection**: Polls `/api/session?directory=<realpath>&order=desc&parentID=<id>` matching `parentID == session_id` (not title).
- **Manual servers are never killed**: If a live server exists but was not started by this manager (no recorded pane/state for that key), `M.restore_session` refuses to kill it and prints the exact command to run manually.
- **Stale-pane hazard**: `ensure_opencode()` must probe before trusting a recorded pane. A surviving shell with a dead opencode child looks "alive" but answers no probe — the entry is cleared and respawned.
- **Snack fallback**: If no multiplexer usable, `snacks.terminal.open(argv, { cwd, win={position="right"} })` with `argv = {"env","OPENCODE_PASSWORD=...","opencode","--server","http://127.0.0.1:N",...}`.

### UI Entrypoints
- `:OpencodeRestore <ses_id>` — forks via API, adopts session. Tab-completes via `opencode session list --format json`.
- `<leader>os` — Snacks picker of project sessions (filtered by `directory` from CLI payload), confirms to fork.

### Implementation Notes
- `start_server(entry, cwd)` starts `opencode serve --port N` detached, captures password from stdout log file, stores PID for cleanup.
- `restart_pane(entry, cwd, args)` stops server (SIGTERM PID) + TUI (C-c), waits for port free, starts fresh server, restarts TUI with new args. For herdr: closes old pane, creates fresh split.
- `tui_argv(entry, extra)` returns `{"env","OPENCODE_PASSWORD=...","opencode","--server","http://127.0.0.1:N",...}` — portable across tmux/herdr/Snacks.
- `adopt(url, password)` sets plugin `server.url` and `server.password` so it can authenticate.
- `rel_time(ms)` uses `os.time()` (wall-clock) against epoch-millisecond `updated`/`created`; `vim.uv.now()` is monotonic.
- `vim.notify` defaults to `INFO`; only actual failures use `ERROR`.
- `Snacks.picker.pick` expects `(opts)` with `opts.items` — do not pass items list as first argument.
- `fetch_sessions()` uses `vim.fn.jobstart` with `cwd` to avoid blocking; completion uses `vim.system`.
