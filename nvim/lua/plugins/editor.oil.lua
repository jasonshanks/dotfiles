return {
  {
    "stevearc/oil.nvim",
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
}
