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
      php = { "php_prettier" },
    },
    formatters = {
      php_prettier = {
        command = vim.fn.expand("~/node_modules/.bin/prettier"),
        args = function(ctx)
          return {
            "--stdin-filepath",
            ctx.filename,
            "--parser=php",
            "--plugin=@prettier/plugin-php"
          }
        end,
        stdin = true,
      },
    },
  },
}
