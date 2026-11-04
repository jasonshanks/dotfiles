# Agent Configuration

## Build/Lint/Test Commands
- Formatting: `stylua .` (uses stylua.toml config)
- Rex/OpenCode stub tests: `nvim --headless -u NONE -l tests/rex_shell_spec.lua` (from `nvim/`); uses an in-memory Rex/OpenCode stub, no real sessions or servers
- Session picker/Ask completion stub tests: `nvim --headless -u NONE -l tests/session_delete_spec.lua` (from `nvim/`); stubs the picker and `opencode session delete`, no real sessions are touched
- Fresh-root Ask stub tests: `nvim --headless -u NONE -l tests/ask_new_session_spec.lua` (from `nvim/`); stubs the promised input, API, and Rex TUI, no real sessions or prompts are touched
- No other test framework used - this is a Neovim configuration repo

## Code Style Guidelines
- Language: Lua
- Indentation: 2 spaces (enforced by stylua)
- Line width: 120 characters
- Naming: snake_case for variables/functions, PascalCase for classes
- Imports: Use relative paths with `require()` for local modules
- Standard Lua with pervasive explicit type annotations (`---@param`/`---@field`) in ai.lua
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

### Multiplexer Backends & Rex
- **Detection precedence**: `rex` > `tmux` > `herdr` > `snacks`. `rex_env()` requires non-empty `REX_SESSION` **and** `REX_BLOCK` plus `rex` on `PATH`; the explicit Rex pair wins over inherited/incidental `TMUX`/`HERDR_PANE_ID`.
- **Retargeting**: `prefer_rex(entry)` runs at the top of `ensure_opencode()` and `M.restore_session()`. Inside Rex it switches an entry recorded from another backend to `mux = "rex"`, clears that backend's `pane` (leaving the pane itself untouched), and records the current session/source. So every OpenCode action, not just `<leader>ot`, uses the persistent Rex block.
- **Rex state** (`mux = "rex"`): `pane` is the ID of a **persistent shell block** that hosts the TUI, `rex_session` scopes lookups, `rex_source` is the anchor block the split was created beside, and `rex_split` is the direction (`"right"`). `src`/`dir` stay herdr-only.
- **Liveness vs TUI**: `pane_alive("rex", pane, session)` runs `rex block ls -s <session> --json` and matches `blocks[].block_id`, so it only means "the block exists"; missing/invalid session or any CLI/JSON failure returns `false`. `rex_block_state(entry, session)` calls `rex block call -s SESSION -b BLOCK process` and classifies the foreground as `"tui"` (`fg_is_opencode`: name/path/argv0 `opencode`), `"shell"` (`fg_is_shell`: `login`, `fish`, `zsh`, `bash`, `sh`, and common interactive shells), `"other"`, or `nil` when the block/process metadata is unavailable. Terminal text is never used. A live block parked at a recognized shell prompt is reusable; anything else must not receive typed text.
- **Start**: `rex split -s SESSION -b ANCHOR --split=right -c CWD --json` with **no command** creates the persistent shell block; `.block_ids[1]` becomes `entry.pane`. The TUI is then typed in with `rex send -s SESSION -b BLOCK <shell-quoted argv>` followed by `rex send-key -s SESSION -b BLOCK enter`. Every argv token is `vim.fn.shellescape`d, so passwords/paths are shell data. Anchor preference is current `$REX_BLOCK`, then stored `rex_source`; if neither survives, omitting `-b` splits the focused block.
- **Reuse (keep the block alive)**: if the block exists and its `rex_block_state` is `"tui"`, interrupt it back to a prompt; if it is `"shell"`, use it directly. In both cases re-confirm `rex_shell_ready` before sending, then type the TUI into that **same block** — never focus a bare prompt and never create a second split. If the foreground is `"other"` (nvim, a pager, ...) or metadata is `nil`, the block is left untouched and one fresh shell split is created beside the current `$REX_BLOCK`/stored `rex_source`; state moves to the new block and the old block is never closed. New splits focus by default; a reused shell block is focused after launch.
- **Resume/restart**: never closes the recorded Rex block. Interrupts only a `"tui"` foreground (retries `ctrl+c`; v2 often needs a second press), re-classifies the block, and only sends argv when it is a confirmed `"shell"`. A foreground of `"other"`/`nil`, or an interrupt that does not yield a prompt, leaves the block untouched and gets a fresh shell split. The detached server is not restarted for a session switch: an authenticating server is kept alive and `opencode --server URL --session <selected_id>` is sent into the confirmed shell block.
- **`<leader>ot`**: inside Rex it persists the detected Rex identity and delegates to `ensure_opencode()`, so it reuses/relaunches the persistent Rex block and never falls back to Snacks merely because Rex env vars are present. Outside Rex, Snacks behavior is unchanged.

### Sessions & Resuming (v2)
- **Targeting**: `Server:resolve_session()` picks newest non-archived **root** session (`parentID=null`) for cwd, sorted by `updated`. Used by both `api/prompt.lua` and `api/command.lua`.
- **Restore resumes directly**: `:OpencodeRestore`/`<leader>os` pass the selected root ID unchanged as `--session <id>`. No `POST /api/session/{id}/fork`, no `POST /api/session {parentID}` child, and no other session mutation. A fork is a separate conversation, so it is never used by restore.
- **Server stays alive**: `M.restore_session` probes the port; an authenticating server is kept running and only the TUI client is reopened on the selected session. A server is started only when nothing is listening. This protects the detached server's active tasks and other clients.
- **Manual servers are never killed**: If a listener exists but was not started by this manager (no recorded state for that key), restore refuses to stop or mutate it and prints the exact command to run manually.
- **Neovim-side caveat**: restore opens the selected ID, but `resolve_session()` still targets the newest root session for later `ask`/command actions. If the selected ID is not newest, those actions may use the newest root; plugin internals are intentionally not monkeypatched.
- **Stale-pane hazard**: `ensure_opencode()` must probe the server and classify the foreground before trusting a recorded pane. A non-Rex pane whose opencode child died is cleared and respawned. A Rex block is reused only when it is a `"tui"` or a recognized `"shell"`; an unrelated foreground (`"other"`) or unreadable metadata is left untouched and triggers one fresh shell split (state moves to the new block, the old block stays open).
- **Snack fallback**: If no multiplexer usable, `snacks.terminal.open(argv, { cwd, win={position="right"} })` with `argv = {"env","OPENCODE_PASSWORD=...","opencode","--server","http://127.0.0.1:N",...}`.

### UI Entrypoints
- `:OpencodeRestore <ses_id>` — resumes the selected existing root session directly with `--session <id>`. It does not fork or create a child session. Tab-completes via `opencode session list --format json`.
- `<leader>oa` — opens OpenCode Ask. It ensures only the detached project server exists before the dialog (never launches a TUI), so cancelling leaves no empty root. After submission it renders the cursor/selection context, creates exactly one root with `POST /api/session {}`, switches the persistent TUI to that exact ID without focusing a Rex block, and prompts that ID directly. The new root is newest afterward, so normal later plugin actions target it. Direct `:OpencodeRestore`/`<leader>os` behavior is unchanged and never forks.
- `<leader>os` — Snacks picker of project sessions (filtered by `directory` from the CLI payload), confirms to the same direct-resume route. Inside the picker `<C-x>` (input and list) asks for confirmation and then deletes the selected session with `opencode session delete <id>` in the project cwd. The confirmation warns that history and **all child sessions** (including active subagents) are removed permanently with no undo. Deletion is asynchronous; on success the picker closes and reopens with a fresh session list, and on failure it stays open with an error.

### Implementation Notes
- `start_server(entry, cwd)` starts `opencode serve --port N` detached, captures password from stdout log file, stores PID alongside state (informational/ownership only — no lifecycle path kills by PID).
- `M.restore_session(session_id)` validates the ID, resolves the project port, refuses foreign listeners, then calls `start_tui` (server alive) or `spawn_tui` (no listener) with `{"--session", session_id}`. It never forks and never stops a live server; Rex reuse is handled inside `start_tui`.
- `assign_port(key, cwd, entry)` centralizes port resolution + credential invalidation (clears `entry.password`/`entry.server_pid` when the resolved port changes); `commit_entry(key, state, entry)` centralizes the persist-`state` + `adopt(url, password)` tail shared by every wholesale server launch/adopt path.
- `rex_launch(entry, cwd, session, argv, focus, known_state, opts)` is the single owner of the Rex launch/reuse state machine (reuse "tui"/"shell", interrupt only "tui", re-confirm "shell" before typing, one fresh split otherwise, focus per caller policy); `start_tui` (`focus_reused_only`) and `ensure_opencode` (argv builder `before_send` that probes/starts the server after block confirmation) both delegate to it.
- `tui_argv(entry, extra)` returns `{"env","OPENCODE_PASSWORD=...","opencode","--server","http://127.0.0.1:N",...}` — portable across tmux/herdr/Snacks.
- `adopt(url, password)` sets plugin `server.url` and `server.password` so it can authenticate.
- `rel_time(ms)` uses `os.time()` (wall-clock) against epoch-millisecond `updated`/`created`; `vim.uv.now()` is monotonic.
- `vim.notify` defaults to `INFO`; only actual failures use `ERROR`.
- `Snacks.picker.pick` expects `(opts)` with `opts.items` — do not pass items list as first argument.
- **Ask completion sources**: Blink's global source list includes `codeium`, but `sources.per_filetype.opencode_ask = { "lsp", "buffer" }` in `lua/plugins/lsp.lua` excludes Codeium from the OpenCode Ask input while keeping `opencode_ask_cmp` (LSP) and buffer completions. Do not disable Codeium globally for general buffers.
- **Codeium virtual text**: `lua/plugins/ai.lua` sets `virtual_text.filetypes.opencode_ask = false` (and `snacks_input = false`) so WindSurf's own virtual-text completion request never fires in transient inputs. `enable_cmp_source = false` only covers nvim-cmp; Blink is controlled by `sources.per_filetype` above.
- `fetch_sessions()` uses `vim.fn.jobstart` with `cwd` to avoid blocking; completion uses `vim.system`.
