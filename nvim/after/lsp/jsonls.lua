-- JSON schema support (LazyVim lang.json extra via SchemaStore.nvim).
---@type vim.lsp.Config
return {
  settings = {
    json = {
      format = { enable = true },
      validate = { enable = true },
    },
  },
  -- Lazy-load SchemaStore only when a JSON server actually starts.
  before_init = function(_, config)
    config.settings = config.settings or {}
    config.settings.json = config.settings.json or {}
    config.settings.json.schemas = config.settings.json.schemas or {}
    vim.list_extend(config.settings.json.schemas, require("schemastore").json.schemas())
  end,
}
