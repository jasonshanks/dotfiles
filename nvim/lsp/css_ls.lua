---@type vim.lsp.Config
return {
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = {
    "css",
    "scss",
    "less",
    -- Enable CSS intelligence inside these syntaxes via embedded language features
    "html",
    "javascriptreact",
    "typescriptreact",
    "svelte",
    "vue",
    "astro",
  },
  root_markers = {
    "package.json",
    ".git",
    "postcss.config.js",
    "postcss.config.cjs",
    "tailwind.config.js",
    "tailwind.config.cjs",
  },

  settings = {
    css = {
      validate = true,
      lint = {
        -- Adjust severities as desired: "error" | "warning" | "ignore"
        unknownAtRules = "ignore", -- often noisy with Tailwind/PostCSS
        unknownProperties = "warning",
        unknownVendorSpecificProperties = "warning",
        unknownMsPseudoElement = "warning",
        duplicateProperties = "warning",
        emptyRules = "warning",
        importStatementMissingComma = "error",
        boxModel = "warning",
        vendorPrefix = "warning",
        zeroUnits = "warning",
        fontFaceProperties = "warning",
        hexColorLength = "warning",
        argumentsInColorFunction = "warning",
        ieHack = "ignore",
        important = "warning",
        propertyIgnoredDueToDisplay = "warning",
        universalSelector = "warning",
        unknownUnit = "warning",
        selectorType = "warning",
        unknownFunction = "warning",
        invalidProperty = "warning",
      },
      completion = {
        triggerPropertyValueCompletion = true,
        completePropertyWithSemicolon = true,
      },
      format = {
        enable = false, -- keep false if you use prettier or a dedicated formatter
      },
    },
    scss = {
      validate = true,
      lint = {
        unknownAtRules = "ignore", -- allow @use/@forward and custom mixins
      },
      completion = {
        completePropertyWithSemicolon = true,
      },
      format = { enable = false },
    },
    less = {
      validate = true,
      lint = {
        unknownAtRules = "ignore",
      },
      completion = {
        completePropertyWithSemicolon = true,
      },
      format = { enable = false },
    },

    -- Enable CSS features inside other filetypes when supported
    html = {
      validate = true,
    },

    -- Snippet/hover support improvements
    controls = {
      showDeprecated = true,
    },

    -- Telemetry
    telemetry = { enable = false },
  },

  -- Optional: provide snippet support etc.
  capabilities = (function()
    local ok, cmp = pcall(require, "cmp_nvim_lsp")
    if ok then
      return cmp.default_capabilities()
    end
    return vim.lsp.protocol.make_client_capabilities()
  end)(),

  on_new_config = function(new_config, root_dir)
    -- If you need to pass custom data path or settings per project, do it here.
    -- Example: normalize cmd if installed via npm locally:
    -- local local_server = root_dir .. "/node_modules/.bin/vscode-css-language-server"
    -- if vim.fn.executable(local_server) == 1 then
    --     new_config.cmd = { local_server, "--stdio" }
    -- end
  end,

  on_attach = function(client, bufnr)
    -- Keymaps or buffer-local tweaks go here
    -- Example: disable server formatting if you use prettier/null-ls
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}
