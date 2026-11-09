---@type vim.lsp.Config
return {
  cmd = { "emmet-language-server", "--stdio" },
  filetypes = {
    "astro",
    "css",
    "eruby",
    "html",
    "htmlangular",
    "htmldjango",
    "javascriptreact",
    "less",
    "php",
    "pug",
    "sass",
    "scss",
    "svelte",
    "templ",
    "typescriptreact",
    "vue",
  },
  init_options = {
    html = {
      options = {
        -- Enable HTML completion in PHP files
        ["bem.enabled"] = true,
      },
    },
    -- Configure PHP to include HTML
    includeLanguages = {
      php = "html",
    },
    -- Enable emmet for PHP files with HTML context
    showExpandedAbbreviation = "always",
    showAbbreviationSuggestions = true,
  },
}
