---@type vim.lsp.Config
return {
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = {
    "html",
    -- Optional template-like filetypes you may want:
    -- "php",            -- enables HTML features in HTML-heavy PHP templates (no PHP parsing)
    -- "templ",
    -- "erb",
    -- "handlebars",
    -- "mustache",
    -- "astro",
  },
  root_markers = {
    "package.json",
    ".git",
    "postcss.config.js",
    "postcss.config.cjs",
    "tailwind.config.js",
    "tailwind.config.cjs",
    ".prettierrc",
    ".prettierrc.js",
    ".prettierrc.cjs",
    ".prettierrc.json",
  },

  settings = {
    html = {
      validate = {
        scripts = true,
        styles = true,
      },
      format = {
        enable = false, -- keep false if you use prettier/conform
        wrapAttributes = "auto", -- "auto" | "force" | "force-aligned" | "force-expand-multiline"
        wrapLineLength = 120,
        unformatted = "pre,code,textarea",
        contentUnformatted = "pre,code,textarea",
        indentInnerHtml = false,
        preserveNewLines = true,
        endWithNewline = false,
      },
      hover = {
        documentation = true,
        references = true,
      },
      suggest = {
        html5 = true,
      },
      trace = { server = "off" }, -- "off" | "messages" | "verbose"
    },

    css = { validate = true }, -- validate embedded <style> blocks
    javascript = { validate = true }, -- validate embedded <script> blocks

    telemetry = { enable = false },
  },

  on_new_config = function(new_config, root_dir)
    -- Prefer local project server if present
    -- local local_server = root_dir .. "/node_modules/.bin/vscode-html-language-server"
    -- if vim.fn.executable(local_server) == 1 then
    --     new_config.cmd = { local_server, "--stdio" }
    -- end
  end,

  on_attach = function(client, bufnr)
    -- Disable LSP formatting to avoid conflicts with external formatters
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
    -- Add your buffer-local keymaps here if desired
  end,
}
