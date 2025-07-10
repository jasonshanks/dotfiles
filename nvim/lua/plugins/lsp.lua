return {
  {
    "mason-org/mason.nvim",
    opts = {
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "lua_ls",
        -- "css-lsp",
        -- "emmet-language-server",
        "intelephense",
        -- "php-cs-fixer",
        -- "phpcs",
        "tailwindcss",
        "ts_ls",
        "rust_analyzer",
        "gopls",
        "clangd",
      },
    },
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
  },
}
