-- 🔬 LSP: Language Server Protocol stack — completion, diagnostics, formatting, and type info

return {
  {
    "saghen/blink.cmp",
    dependencies = {
      "rafamadriz/friendly-snippets",
      "Exafunction/windsurf.nvim",
    },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
      -- 'super-tab' for mappings similar to vscode (tab to accept)
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- All presets have the following mappings:
      -- C-space: Open menu or open docs if already open
      -- C-n/C-p or Up/Down: Select next/previous item
      -- C-e: Hide menu
      -- C-k: Toggle signature help (if signature.enabled = true)
      --
      -- See :h blink-cmp-config-keymap for defining your own keymap
      keymap = { preset = "super-tab" },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = "mono",
      },

      -- (Default) Only show the documentation popup when manually triggered
      completion = { documentation = { auto_show = false } },

      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        default = { "lsp", "buffer", "snippets", "path", "codeium" },
        providers = {
          codeium = { name = "Codeium", module = "codeium.blink", async = true },
        },
      },
      -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
      -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
      -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
      --
      -- See the fuzzy documentation for more information
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },

  {
    -- Mason for package installation
    "mason-org/mason.nvim",
    opts = {
      ui = {
        auto_update_packages = true,
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },

  {
    -- Disable auto-configuration in favour of native lspconfig
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {},
      automatic_installation = false,
      automatic_setup = false, -- must be false otherwise duplicate LSPs
      automatic_enable = false, -- disable automatic server setup
      handlers = {}, -- Empty = no auto-configuration
    },
  },

  {
    -- Native LSP configuration
    -- [Default configs](https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md)
    -- Place any custom configs in `/lsp/{language}.lua`
    "neovim/nvim-lspconfig",
    config = function()
      -- Base LSP enablers
      vim.lsp.enable({
        "bashls", -- Bash shell
        "cssls", -- CSS
        "emmet_language_server", -- Emmet.io
        "fish_lsp", -- Fish shell
        "gopls", -- Go
        "html", -- HTML
        "intelephense", -- PHP (prefer over phpactor)
        "jsonls",
        "lua_ls", -- Lua
        "pyright", -- Python
        "rust_analyzer", -- Rust
        -- "tailwindcss", -- CSS framework
        "ts_ls", -- TypeScript
      })

      vim.diagnostic.config({ virtual_text = true })
    end,
  },

  -- Incremental rename
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    config = true,
  },

  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        php = { "phpcs" },
      },
      linters = {
        phpcs = {
          cmd = "phpcs",
          args = {
            "--standard=" .. vim.fn.expand("$HOME/.config/.phpcs.xml"),
            "--report=json",
            "-q",
            "-s",
            "--basepath=" .. vim.fn.getcwd(),
            "-",
          },
          stdin = true,
          ignore_exitcode = true,
          parser = function(output, bufnr)
            -- If output is empty or contains an error message, return empty diagnostics
            if output == "" or output:match("^ERROR: ") then
              return {}
            end

            -- Attempt to decode JSON
            local ok, decoded = pcall(vim.json.decode, output)
            if not ok or not decoded or not decoded.files then
              return {}
            end

            local diagnostics = {}
            -- Get the first (and usually only) file's messages
            for _, file in pairs(decoded.files) do
              for _, message in ipairs(file.messages or {}) do
                table.insert(diagnostics, {
                  lnum = (message.line or 1) - 1,
                  col = (message.column or 1) - 1,
                  end_lnum = (message.line or 1) - 1,
                  end_col = (message.column or 1),
                  severity = message.type == "ERROR" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
                  message = message.message or "Unknown error",
                  source = "phpcs",
                })
              end
            end
            return diagnostics
          end,
        },
      },
    },
  },

  {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },

  {
    "stevearc/conform.nvim",
    opts = {
      -- NOTE: enable if not using LazyVim
      -- format_on_save = {
      --   timeout_ms = 500,
      --   lsp_fallback = true,
      -- },
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        fish = { "fish_indent" },
        python = { "isort", "black" },
        javascript = { "biome", "prettierd", "prettier" },
        typescript = { "biome", "prettierd", "prettier" },
        javascriptreact = { "biome", "prettierd", "prettier" },
        typescriptreact = { "biome", "prettierd", "prettier" },
        svelte = { "prettierd", "prettier" },
        css = { "prettierd", "prettier" },
        html = { "prettierd", "prettier" },
        json = { "prettierd", "prettier" },
        yaml = { "prettierd", "prettier" },
        markdown = { "prettierd", "prettier" },
        graphql = { "prettierd", "prettier" },
        liquid = { "prettierd", "prettier" },
        php = { "php_smart_formatter" },
        ["_"] = { "trim_whitespace" },
      },
      formatters = {
        php_smart_formatter = {
          command = function(ctx)
            -- Enhanced WordPress detection with directory traversal
            local function is_wordpress_project()
              -- Function to traverse up directory tree looking for WordPress indicators
              local function traverse_up_for_wordpress(start_dir, max_depth)
                local current_dir = start_dir
                local depth = 0

                while current_dir ~= "" and depth < max_depth do
                  -- Check for wp-config.php
                  if vim.fn.filereadable(current_dir .. "/wp-config.php") == 1 then
                    return true
                  end

                  -- Check for wp-content directory
                  if vim.fn.isdirectory(current_dir .. "/wp-content") == 1 then
                    return true
                  end

                  -- Check if we're inside wp-content/themes (common theme location)
                  local parent = vim.fn.fnamemodify(current_dir, ":h")
                  local grandparent = vim.fn.fnamemodify(parent, ":h")
                  local greatgrandparent = vim.fn.fnamemodify(grandparent, ":h")

                  -- Check for the pattern: wp-root/wp-content/themes/theme-name
                  if
                    vim.fn.fnamemodify(parent, ":t") == "themes"
                    and vim.fn.fnamemodify(grandparent, ":t") == "wp-content"
                    and greatgrandparent ~= grandparent
                    and vim.fn.filereadable(greatgrandparent .. "/wp-config.php") == 1
                  then
                    return true
                  end

                  current_dir = vim.fn.fnamemodify(current_dir, ":h")
                  depth = depth + 1
                end

                return false
              end

              -- First, try directory traversal up to reasonable depth
              if traverse_up_for_wordpress(vim.fn.getcwd(), 8) then
                return true
              end

              -- Check composer.json for WordPress dependencies (traverses up automatically)
              local composer_path = vim.fn.findfile("composer.json", ".;")
              if composer_path ~= "" then
                local content = table.concat(vim.fn.readfile(composer_path), "\n")
                if
                  content:match('"wpcs"')
                  or content:match('"wordpress"')
                  or content:match('"wp%-cli"')
                  or content:match('"roots/wordpress"')
                  or content:match('"johnpbloch/wordpress"')
                then
                  return true
                end
              end

              -- Check for phpcs.xml with WordPress rules (traverses up automatically)
              local phpcs_path = vim.fn.findfile("phpcs.xml", ".;")
              if phpcs_path ~= "" then
                local content = table.concat(vim.fn.readfile(phpcs_path), "\n")
                if content:match("WordPress") then
                  return true
                end
              end

              return false
            end

            local is_wordpress = is_wordpress_project()
            local has_php_cs_fixer = vim.fn.executable("php-cs-fixer") == 1
            local has_phpcbf = vim.fn.executable("phpcbf") == 1

            -- Default to phpcbf for WordPress projects, fallback to php-cs-fixer
            if is_wordpress and has_phpcbf then
              return "phpcbf"
            elseif has_php_cs_fixer then
              return "php-cs-fixer"
            elseif has_phpcbf then
              return "phpcbf"
            else
              return "echo" -- fallback that does nothing
            end
          end,
          args = function(ctx)
            local formatter = ctx.command

            if formatter == "phpcbf" then
              -- Use the configured phpcs.xml if it exists, otherwise WordPress standard
              local phpcs_config = vim.fn.expand("$HOME/.config/.phpcs.xml")
              if vim.fn.filereadable(phpcs_config) == 1 then
                return {
                  "--standard=" .. phpcs_config,
                  "--no-cache",
                  "$FILENAME",
                }
              else
                return {
                  "--standard=WordPress",
                  "--no-cache",
                  "$FILENAME",
                }
              end
            elseif formatter == "php-cs-fixer" then
              -- Check for project config in current directory and parents
              local config_files = {
                ".php-cs-fixer.php",
                ".php-cs-fixer.dist.php",
                "php-cs-fixer.php",
              }

              local has_config = false
              for _, file in ipairs(config_files) do
                if vim.fn.findfile(file, ".;") ~= "" then
                  has_config = true
                  break
                end
              end

              if has_config then
                return {
                  "fix",
                  "--using-cache=no",
                  "--allow-risky=no",
                  "--allow-unsupported-php-version=yes",
                  "$FILENAME",
                }
              else
                return {
                  "fix",
                  "--using-cache=no",
                  "--allow-risky=no",
                  "--allow-unsupported-php-version=yes",
                  "--rules=@PSR12",
                  "$FILENAME",
                }
              end
            else
              return { "$FILENAME" }
            end
          end,
          stdin = false,
        },
        biome = {
          command = "biome",
          args = { "format", "--write", "$FILENAME" },
          stdin = false,
        },
      },
    },
  },

  {
    "simrat39/symbols-outline.nvim",
    keys = { { "<leader>cs", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" } },
    cmd = "SymbolsOutline",
    opts = {
      position = "right",
    },
  },
}
