# Neovim Config Notes

## Layout

- This config uses native `vim.pack`. `init.lua` loads `lua/config/`, then `lua/plugins/init.lua` adds plugins and loads their setup modules.
- `lua/plugins/` contains plugin setup; `lua/utils/` contains shared helpers; `after/lsp/` contains per-server overrides.
- The active plugin set is defined in `lua/plugins/init.lua`.

## Config-specific guardrails

- Colorscheme/background behavior is intentionally customized in `lua/plugins/ui.lua` and `lua/utils/colorscheme.lua`; do not change it unless asked.
- Navigation ownership is deliberate: tmux-navigator default mappings are disabled; Herdr owns `<C-h/j/k/l>` and `<C-Arrow>` outside Rex; rex-navigator claims `<C-h/j/k/l>` inside Rex; TUIOS keeps Alt-arrow mappings. Avoid overlapping mappings.
- Snacks input and picker are enabled and explicitly wired to `vim.ui.input` / `vim.ui.select` in `lua/plugins/ui.lua`.
- Copilot completions flow through the Blink adapter in `lua/plugins/lsp.lua`; do not restore Copilot's separate suggestion/panel UI.
- `lua/plugins/ai.lua` and `lua/utils/opencode.lua` manage per-project OpenCode sessions across muxes. Never stop a foreign server or send commands to an unverified mux pane/block.

## Verification

- Lua uses 2-space indentation and 120-column width (`stylua.toml`). Run `stylua --check <changed Lua files>` and `git diff --check`.
- Use focused headless probes with `nvim --headless -u nvim/init.lua`; make assertions fail with `vim.cmd("cquit 1")` because Neovim may otherwise exit 0 after Lua errors.
- Mason tools may need an explicit install in headless sessions, e.g. `nvim --headless -u nvim/init.lua +'MasonInstall black isort' +qa`.
