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