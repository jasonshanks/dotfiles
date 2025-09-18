---@type vim.lsp.Config
return {
  cmd = { "intelephense", "--stdio" },
  filetypes = { "php" },
  root_markers = {
    "composer.json",
    "composer.lock",
    ".git",
    ".intelephense",
    ".intelephense.json",
    "wp-config.php",
  },

  -- init_options = { licenceKey = vim.env.INTELEPHENSE_LICENSE_KEY },

  settings = {
    intelephense = {
      files = {
        exclude = {
          "**/.git/**",
          "**/.svn/**",
          "**/.hg/**",
          "**/node_modules/**",
          "**/.history/**",
          "**/.cache/**",
          "**/dist/**",
          "**/build/**",

          -- Common vendor test dirs
          "**/vendor/**/{Test,test,Tests,tests}/**",

          -- Exclude WordPress core (adjust paths if WordPress is vendored)
          "**/wp-admin/**",
          "**/wp-includes/**",
          -- If your project includes WordPress in a subfolder (e.g., wordpress/)
          "**/wordpress/wp-admin/**",
          "**/wordpress/wp-includes/**",
          -- If using Bedrock-style structure
          "**/web/wp/wp-admin/**",
          "**/web/wp/wp-includes/**",
        },
        -- maxSize = 5000000,
      },
      diagnostics = {
        enable = true,
      },
      environment = {
        phpVersion = "8.2",
        -- If you exclude WP core above and still want symbols resolved,
        -- rely on stubs (see stubs list) rather than includePaths.
        -- includePaths = { "/abs/path/to/wp-includes", "/abs/path/to/wp-admin/includes" },
      },
      telemetry = {
        enabled = false,
      },
      completion = {
        fullyQualifyGlobalConstantsAndFunctions = true,
        insertUseDeclaration = true,
        triggerParameterHints = true,
        maxItems = 200,
      },
      format = {
        enable = false,
      },
      stubs = {
        "apache",
        "bcmath",
        "bz2",
        "calendar",
        "core",
        "ctype",
        "curl",
        "date",
        "dom",
        "fileinfo",
        "filter",
        "gd",
        "gettext",
        "hash",
        "iconv",
        "imap",
        "intl",
        "json",
        "libxml",
        "mbstring",
        "mcrypt",
        "mysql",
        "mysqli",
        "openssl",
        "pcntl",
        "pcre",
        "PDO",
        "pdo_mysql",
        "pdo_sqlite",
        "pgsql",
        "Phar",
        "readline",
        "SimpleXML",
        "soap",
        "sockets",
        "sodium",
        "sqlite3",
        "standard",
        "tidy",
        "tokenizer",
        "xml",
        "xmlreader",
        "xmlwriter",
        "xdebug",
        "yaml",
        "zip",
        "zlib",

        -- WordPress-related stubs
        "wordpress",
        "wp-cli",
        -- Optional plugin stubs if you use them:
        -- "woocommerce",
        -- "acf-pro",
        -- "polylang",
      },

      -- Optional helper list of common WP globals (documentation purpose)
      diagnosticsUndefinedGlobals = {
        "wpdb",
        "wp_query",
        "post",
        "wp_rewrite",
        "current_user",
        "wp",
        "wp_the_query",
      },
    },
  },

  on_attach = function(client, bufnr)
    -- Disable LSP formatting; use your external formatter (Conform) instead.
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}
