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
}
