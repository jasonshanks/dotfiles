-- 🛠️ Tools: productivity integrations — file management, fuzzy finding, and external app bridges

return {
  {
    "georgeharker/comment-tasks.nvim",
    config = function()
      require("comment-tasks").setup({
        default_provider = "clickup", -- Choose your preferred provider

        providers = {
          clickup = {
            enabled = true,
            api_key_env = "CLICKUP_API_KEY",
            list_id = "192708400",
            statuses = {
              new = "To Do",
              on_hold = "On Hold",
              in_progress = "In Progress",
              review = "In Review",
              completed = "Done",
            },
          },
          github = {
            enabled = true,
            api_key_env = "GITHUB_TOKEN",
            repo_owner = "jasonshanks", -- Required: GitHub username/org
            repo_name = "dotfiles", -- Required: repository name

            -- Optional settings
            default_labels = { "bug", "enhancement" }, -- Default labels for issues
            default_assignee = "jasonshanks", -- Default assignee username
            default_milestone = 1, -- Default milestone ID
          },
          -- Add other providers as needed
        },
      })
    end,
  },

  {
    "stevearc/oil.nvim",
    -- "barrettruth/canola.nvim", -- NOTE: trying Canola fork with more recent updates.

    ---@module 'oil'
    ---@type oil.SetupOpts
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open Oil" },
    },
    opts = {
      keymaps = {
        ["gd"] = {
          desc = "Toggle file detail view",
          callback = function()
            detail = not detail
            if detail then
              require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
            else
              require("oil").set_columns({ "icon" })
            end
          end,
        },
      },
    },
    -- Optional dependencies
    dependencies = { { "nvim-mini/mini.icons", opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
  },

  {
    "hedyhli/outline.nvim",
    lazy = true,
    cmd = { "Outline", "OutlineOpen" },
    keys = { -- Example mapping to toggle outline
      { "<leader>oo", "<cmd>Outline<CR>", desc = "Toggle outline" },
    },
    opts = {
      -- Your setup opts here
    },
  },

  ---@type LazySpec
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    keys = {
      { "_", "<cmd>Yazi<cr>", desc = "Open Yazi (current file)" },
      { "<Leader>cw", "<cmd>Yazi cwd<cr>", desc = "Open Yazi (cwd)" },
    },
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    ---@type YaziConfig | {}
    opts = {
      -- if you want to open yazi instead of netrw, see below for more info
      open_for_directories = false,
      keymaps = {
        show_help = "<f1>",
      },
      -- Enable debug mode to get more information
      debug = true,
    },
    -- 👇 if you use `open_for_directories=true`, this is recommended
    init = function()
      -- Enable debug logging
      vim.g.yazi_debug = true
      -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
      -- vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
  },
}
