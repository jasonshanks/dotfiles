-- ESLint language server (LazyVim linting.eslint extra).
---@type vim.lsp.Config
return {
  settings = {
    -- helps eslint find the eslintrc when it's placed in a subfolder
    workingDirectories = { mode = "auto" },
    format = true,
  },
}
