-- 🔬 LSP: Language Server Protocol stack — completion, diagnostics, formatting, and type info

--------------------------------------------------------------------------------
-- Completion (blink.cmp)
--------------------------------------------------------------------------------
require("blink.cmp").setup({
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
  keymap = { preset = "super-tab" },

  appearance = {
    -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
    -- Adjusts spacing to ensure icons are aligned
    nerd_font_variant = "mono",
  },

  -- (Default) Only show the documentation popup when manually triggered
  completion = { documentation = { auto_show = false } },

  sources = {
    default = { "lsp", "buffer", "ripgrep", "snippets", "path", "copilot" },
    -- OpenCode Ask provides its own context-placeholder LSP completion. Avoid
    -- sending every prompt character to Copilot (its blink source is global).
    per_filetype = {
      opencode_ask = { "lsp", "buffer" },
    },
    providers = {
      copilot = {
        name = "copilot",
        module = "blink-cmp-copilot",
        score_offset = 100,
        async = true,
      },
      ripgrep = {
        module = "blink-ripgrep",
        name = "Ripgrep",
        ---@module "blink-ripgrep"
        ---@type blink-ripgrep.Options
        opts = {
          backend = {
            use = "gitgrep-or-ripgrep",
          },
        },
      },
    },
  },

  -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
  -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
  -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
  fuzzy = { implementation = "prefer_rust_with_warning" },
})

--------------------------------------------------------------------------------
-- Mason
--------------------------------------------------------------------------------
require("mason").setup({
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
})

require("mason-tool-installer").setup({
  ensure_installed = {
    "tree-sitter-cli",
    "lua-language-server",
    "black",
    "isort",
    "prettier",
    "prettierd",
    "selene",
    "shellcheck",
    "shfmt",
    "stylua",
    "eslint-lsp",
    "oxlint",
    "oxfmt",
    "tailwindcss-language-server",
    "vtsls",
    "copilot-language-server",
    "rust-analyzer",
  },
  auto_update = false,
  run_on_start = true,
})

--------------------------------------------------------------------------------
-- Native LSP configuration
--------------------------------------------------------------------------------
-- [Default configs](https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md)
-- Place any custom configs in `after/lsp/{language}.lua`
local capabilities = {
  workspace = {
    fileOperations = {
      didRename = true,
      willRename = true,
    },
  },
}
vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(capabilities),
})

vim.lsp.enable({
  "bashls", -- Bash shell
  "cssls", -- CSS
  "emmet_language_server", -- Emmet.io
  "eslint", -- ESLint (LazyVim linting.eslint extra)
  "fish_lsp", -- Fish shell
  "gopls", -- Go
  "html", -- HTML
  "intelephense", -- PHP (prefer over phpactor)
  "jsonls",
  "lua_ls", -- Lua
  "marksman", -- Markdown
  "pyright", -- Python
  "rust_analyzer", -- Rust
  -- "tailwindcss", -- CSS framework
  "taplo", -- TOML
  "oxlint", -- JavaScript/TypeScript linter
  "vtsls", -- TypeScript
})

-- Diagnostics: LazyVim-like presentation with the inline virtual text disabled in
-- favour of tiny-inline-diagnostic.
vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  virtual_text = false,
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.HINT] = " ",
      [vim.diagnostic.severity.INFO] = " ",
    },
  },
})

-- Inlay hints (enabled for every capable server, except `vue`) and LSP folding.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then
      return
    end

    local bufnr = event.buf
    if
      client:supports_method("textDocument/inlayHint", bufnr)
      and vim.bo[bufnr].buftype == ""
      and vim.bo[bufnr].filetype ~= "vue"
    then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end

    if client:supports_method("textDocument/foldingRange", bufnr) then
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == bufnr then
          if vim.wo[win].foldmethod ~= "expr" then
            vim.wo[win].foldmethod = "expr"
          end
          -- LSP folding takes priority over the Tree-sitter foldexpr set on
          -- FileType, so replace it (and any empty value); leave unrelated
          -- user overrides alone.
          local foldexpr = vim.wo[win].foldexpr
          if foldexpr == "" or foldexpr:find("treesitter", 1, true) then
            vim.wo[win].foldexpr = "v:lua.vim.lsp.foldexpr()"
          end
        end
      end
    end
  end,
})

--------------------------------------------------------------------------------
-- Diagnostics
--------------------------------------------------------------------------------
-- Tiny Inline Diagnostics
require("tiny-inline-diagnostic").setup({})

-- Incremental rename
require("inc_rename").setup()

-- Linting
local lint = require("lint")
lint.linters_by_ft = {
  php = { "phpcs" },
  markdown = { "markdownlint-cli2" }, -- LazyVim lang.markdown extra
}
lint.linters.phpcs = {
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
          end_col = message.column or 1,
          severity = message.type == "ERROR" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
          message = message.message or "Unknown error",
          source = "phpcs",
        })
      end
    end
    return diagnostics
  end,
}

vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  callback = function()
    require("lint").try_lint()
  end,
})

--------------------------------------------------------------------------------
-- Diagnostics list / symbols
--------------------------------------------------------------------------------
require("trouble").setup({})

vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
vim.keymap.set(
  "n",
  "<leader>xX",
  "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
  { desc = "Buffer Diagnostics (Trouble)" }
)
vim.keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
vim.keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })
vim.keymap.set(
  "n",
  "<leader>cl",
  "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
  { desc = "LSP Definitions / references / ... (Trouble)" }
)
vim.keymap.set("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })

--------------------------------------------------------------------------------
-- Formatting
--------------------------------------------------------------------------------
require("conform").setup({
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    return {
      timeout_ms = 500,
      lsp_format = "fallback",
    }
  end,
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
    jsonc = { "prettierd", "prettier" },
    yaml = { "prettierd", "prettier" },
    less = { "prettierd", "prettier" },
    scss = { "prettierd", "prettier" },
    vue = { "prettierd", "prettier" },
    markdown = { "prettier", "markdownlint-cli2", "markdown-toc" },
    ["markdown.mdx"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
    graphql = { "prettierd", "prettier" },
    liquid = { "prettierd", "prettier" },
    php = { "php_smart_formatter" },
    ["_"] = { "trim_whitespace" },
  },
  formatters = {
    -- LazyVim lang.markdown extra: only run these when the buffer asks for them.
    ["markdown-toc"] = {
      condition = function(_, ctx)
        for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
          if line:find("<!%-%- toc %-%->") then
            return true
          end
        end
      end,
    },
    ["markdownlint-cli2"] = {
      condition = function(_, ctx)
        local diag = vim.tbl_filter(function(d)
          return d.source == "markdownlint"
        end, vim.diagnostic.get(ctx.buf))
        return #diag > 0
      end,
    },
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
})

-- Toggle autoformat globally / per buffer
vim.keymap.set("n", "<leader>uf", function()
  vim.g.disable_autoformat = not vim.g.disable_autoformat
  vim.notify(
    vim.g.disable_autoformat and "Autoformat disabled (global)" or "Autoformat enabled (global)",
    vim.log.levels.INFO
  )
end, { desc = "Toggle autoformat (global)" })

vim.keymap.set("n", "<leader>uF", function()
  vim.b.disable_autoformat = not vim.b.disable_autoformat
  vim.notify(
    vim.b.disable_autoformat and "Autoformat disabled (buffer)" or "Autoformat enabled (buffer)",
    vim.log.levels.INFO
  )
end, { desc = "Toggle autoformat (buffer)" })
