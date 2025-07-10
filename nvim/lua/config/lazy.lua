-- Lazy.nvim Bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  local result = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("Failed to clone lazy.nvim: " .. result)
  end
end
vim.opt.rtp:prepend(lazypath)

-- LazyVim Core Configuration
require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    {
      "LazyVim/LazyVim",
      import = "lazyvim.plugins",
      opts = {
        colorscheme = "tokyonight-night",
        news = {
          lazyvim = true,
          neovim = true,
        },
        format = {
          timeout_ms = 3000,
          async = true, -- NOTE: default: false? not sure reasoning
          quiet = false,
        },
      },
    },

    -- Plugin imports
    -- Language support
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
    { import = "lazyvim.plugins.extras.lang.rust" },

    -- Development tools
    { import = "lazyvim.plugins.extras.linting.eslint" },
    { import = "lazyvim.plugins.extras.formatting.prettier" },
  },

  -- Default Plugin Behavior
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = true, -- NOTE: default: false? not sure why as seems to defeat purpose of lazy.
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },

  -- Plugin Management
  checker = { enabled = true }, -- automatically check for plugin updates

  -- Performance Optimisation
  performance = {
    cache = {
      enabled = true,
      -- disable_events = {},
    },
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        "netrwPlugin",
        "rplugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },

  -- UI Customisation
  ui = {
    custom_keys = {
      ["<localleader>d"] = function(plugin)
        if type(dd) == "function" then
          dd(plugin)
        else
          vim.notify("Debug function 'dd' not available", vim.log.levels.WARN)
        end
      end,
    },
  },
  debug = false,
})
