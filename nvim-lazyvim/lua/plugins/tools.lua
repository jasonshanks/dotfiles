-- 🛠️ Tools: productivity integrations — file management, fuzzy finding, and external app bridges
local detail = false

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
    ---@module 'oil'
    ---@type oil.SetupOpts
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open Oil" },
    },
    opts = {
      win_options = {
        signcolumn = "yes:2",
      },
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
    dependencies = {
      { "nvim-mini/mini.icons", opts = {} },
    },
  },
  {
    "refractalize/oil-git-status.nvim",

    dependencies = {
      "stevearc/oil.nvim",
    },

    config = true,
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
}
