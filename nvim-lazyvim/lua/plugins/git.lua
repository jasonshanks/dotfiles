-- 🐙 Git: version control integration — status, diffs, and conflict resolution

return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {},
  },

  {
    "sindrets/diffview.nvim",
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
      { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
    },
  },
}
