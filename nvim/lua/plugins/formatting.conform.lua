return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        fish = { "fish_indent" },
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
        php = { "php_cs_fixer", "phpcbf", "php_prettier" }, -- try php-cs-fixer first, fallback to phpcbf
        ["_"] = { "trim_whitespace" },
      },
      formatters = {
        php_cs_fixer = {
          command = "php-cs-fixer",
          stdin = false,
          args = {
            "fix",
            "--using-cache=no",
            "--allow-risky=no",
            "--rules=@PSR12",
            "$FILENAME",
          },
        },
        phpcbf = {
          command = "phpcbf",
          stdin = false,
          args = {
            "--standard=WordPress", -- or omit to let project phpcs.xml decide
            "--no-cache",
            "$FILENAME",
          },
        },
        -- If you want to use Prettier for PHP (plugin-php):
        php_prettier = {
          command = "prettier",
          stdin = true,
          args = function(ctx)
            return {
              "--plugin=@prettier/plugin-php",
              "--parser=php",
              "--stdin-filepath",
              ctx.filename,
            }
          end,
        },
        -- Prettier: default binary is resolved by PATH; you can customize args if needed.
        -- prettier = {
        --     prepend_args = { "--config-precedence", "prefer-file" },
        -- },
      },
    },
  },
}
