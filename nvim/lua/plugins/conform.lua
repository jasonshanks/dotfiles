return {
  "stevearc/conform.nvim",
  event = { "BufWritePre", "BufNewFile" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>F",
      function()
        require("conform").format({ async = true })
      end,
      mode = "",
      desc = "Format buffer",
    },
  },
  ---@module "conform"
  ---@type conform.setupOpts
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
      php = { "php_cs_fixer" },
    },
    default_format_opts = {
      lsp_format = "fallback",
    },
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
        -- Add WordPress-specific configuration
        config = {
          rules = {
            array_syntax = { syntax = "long" },
            binary_operator_spaces = { align_double_arrow = true },
            cast_spaces = { space = "single" },
            concat_space = { spacing = "one" },
            lowercase_keywords = true,
            method_argument_space = { ensure_fully_multiline = true },
            no_unused_imports = true,
            ordered_imports = true,
            single_quote = true,
            ternary_operator_spaces = true,
            visibility_required = true,
          },
        },
      },
      shfmt = {
        prepend_args = { "-i", "2" },
      },
    },
  },
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
