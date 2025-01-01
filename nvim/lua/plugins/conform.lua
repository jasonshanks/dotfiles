return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      svelte = { "prettier" },
      css = { "prettier" },
      html = { "prettier" },
      json = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      graphql = { "prettier" },
      liquid = { "prettier" },
      -- php = { "php_prettier" },
      -- php = { "prettier" },
      php = { "php_cs_fixer", "phpcbf" },
    },
    formatters = {
      php_cs_fixer = {
        command = "php-cs-fixer", -- Homebrew installation
        args = {
          "fix",
          "--rules=@PSR2",
          "--using-cache=no",
          "$FILENAME",
        },
      },
      phpcbf = {
        command = "phpcbf", -- From Composer installation
        args = {
          "--standard=WordPress",
          "$FILENAME",
        },
      },
      -- php_prettier = {
      --   command = vim.fn.expand("~/node_modules/.bin/prettier"),
      --   args = function(ctx)
      --     return {
      --       "--stdin-filepath",
      --       ctx.filename,
      --       "--parser=php",
      --       "--plugin=@prettier/plugin-php"
      --     }
      --   end,
      --   stdin = true,
      -- },
      -- prettier = {
      --   -- Configure prettier for PHP files
      --   args = {
      --     "--plugin=prettier-plugin-php",
      --     "--parser=php",
      --   },
      -- },
    },
  },
}
