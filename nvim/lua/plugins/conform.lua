return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      -- Customize or remove this keymap to your liking
      "<leader>F",
      function()
        require("conform").format({ async = true })
      end,
      mode = "",
      desc = "Format buffer",
    },
  },
  -- This will provide type hinting with LuaLS
  ---@module "conform"
  ---@type conform.setupOpts
  opts = {
    -- Define your formatters
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      php = { "php_cs_fixer" },
    },
    -- Set default options
    default_format_opts = {
      lsp_format = "fallback",
    },
    -- Customize formatters
    formatters = {
    php_cs_fixer = {
        command = "php-cs-fixer",
        args = {
          "fix",
          "--config=" .. vim.fn.expand("$HOME/.config/.php-cs-fixer.php"),
          "--allow-risky=yes",
          "--verbose",
          "-",
        },
        stdin = true,
      },
      shfmt = {
        prepend_args = { "-i", "2" },
      },
    },
  },
  init = function()
    -- If you want the formatexpr, here is the place to set it
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}