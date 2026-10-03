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
## Opencode Integration (Critical)

The `lua/plugins/ai.lua` file contains a per-project OpenCode server manager with these invariants:

### Server Discovery
- **Port must be pinned**: OpenCode 1.18.34 writes no `~/.local/state/opencode/service.json`, so auto-discovery fails. Always pass `--port <N>`.
- **Project isolation**: `x-opencode-directory` header is global in the event stream (`/api/event`) but regular API requests are directory-scoped. Each project gets its own server on a deterministic port (hash 4100-4999).
- **No bare listener**: Running `opencode` or `opencode --session ...` exposes no TCP listener. You MUST pass `--port <N>` to reach the HTTP API.
- **Realpath keys**: State keys are the realpath of the project directory. `vim.fn.getcwd()` returns realpath, and `/api/command`/session endpoints use directory headers. Symlink forms do not match.
- **Probe truth**: `probe(port, cwd)` calls `GET /api/command` with `x-opencode-directory: <realpath>` and only adopts a URL if `location.directory` matches that realpath. Never trust pane liveness alone.

### Sessions & Forking
- **Targeting**: `Server:resolve_session()` picks the newest non-archived **root** session (`parentID=null`) for the current directory, sorted by `updated`. This is used by both `api/prompt.lua` and `api/command.lua` — every nvim action targets it.
- **Restoring doesn't bump `updated`**: `opencode --port N -s <id>` alone does not change `time.created`/`time.updated`. Neither does `PATCH /api/session/<id>` (unchanged title/archived round-trips are no-ops). As a result, a restored session will NOT become the target unless we fork it.
- **Fork is CLI-only**: `opencode --port N -s <id> --fork` creates a **new root** session with `(fork #n)` in its title and a current `created` time, so it becomes the newest. There is no HTTP fork endpoint (`POST /api/session/<id>/fork` returns the SPA HTML). Fork detection polls `/api/session?directory=<realpath>&order=desc&parentID=null` and looks for a new root session whose `title` contains `(fork #`.
- **Manual servers are never killed**: If a live server exists but was not started by this manager (no recorded pane/state for that key), `M.restore_session` refuses to kill it and prints the exact command to run in a split instead.
- **Stale-pane hazard**: `ensure_opencode()` must probe before returning when a pane is recorded. A surviving shell with a dead opencode child looks "alive" but answers no probe — the entry must be cleared and respawned.
- **Snack fallback**: If no multiplexer is usable, fall back to `snacks.terminal.open({ "opencode", "--port", port, ... }, { cwd = cwd, win = { position = "right" } })`. Never spawn bare `opencode` without `--port`.

### UI Entrypoints
- `:OpencodeRestore <ses_id>` — forks and adopts a session for the current project. Tab-completes via `opencode session list --format json`.
- `<leader>os` — Snacks picker of this project's recent sessions (filtered by `directory` from the CLI payload), confirms to fork the chosen session.

### Implementation Notes
- `spawn_tui(entry, cwd, extra)` threads CLI args to all backends (tmux `split-window … -- <argv>`, herdr `pane run <pane> <argv>`, Snacks `argv` passed directly). Uses `unpack` shim (`unpack = unpack or table.unpack`) for LuaJIT.
- `restart_pane()` reloads a managed server in-place: tmux `respawn-pane -k`, herdr sends `C-c` then waits for the port to free before `pane run`, Snacks sends `C-c` then re-runs the line.
- `rel_time(ms)` uses `os.time()` (wall-clock) against epoch-millisecond `updated`/`created`; `vim.uv.now()` is monotonic and cannot be differenced against those values.
- `vim.notify` defaults to `INFO`; only actual failures use `ERROR`. The success messages ("reloading…", "forked … as …") must remain INFO to avoid aborting command callbacks.
- `Snacks.picker.pick` expects `(opts)` with `opts.items` when passing custom items. Do **not** pass the items list as the first argument.
- `fetch_sessions()` uses `vim.fn.jobstart` with `cwd` to avoid blocking; completion uses `vim.system` since synchronous `system` variants behave differently here.
