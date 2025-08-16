return {
  -- Mason for package installation
  {
    "mason-org/mason.nvim",
    opts = {
      ui = {
        check_outdated_packages_on_open = true,
        auto_update_packages = true,
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },
  -- Disable auto-configuration in favour of native lspconfig
  -- {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {},
      automatic_installation = false,
      automatic_setup = false, -- must be false otherwise duplicate lSPs
      automatic_enable = false, -- disable automatic server setup
      handlers = nil, -- Empty = no auto-configuration
    },
  },
  -- Base LSP enablers
  -- [Default configs](https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md)
  -- Place any custom configs in `/lsp/{language}.lua`
  vim.lsp.enable({
    "bashls", -- Bash shell
    "cssls", -- CSS
    "fish_lsp", -- Fish shell
    "gopls", -- Go
    "emmet_language_server", -- Emmet.io
    "lua_ls", -- Lua
    "phpactor", -- PHP (prefer over Intellephense)
    "pyright", -- Python
    "rust_analyzer", -- Rust
    "tailwindcss", -- CSS framework
    "ts_ls", -- TypeScript
  }),
  vim.diagnostic.config({ virtual_text = true }),
}
