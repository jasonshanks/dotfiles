return {
  {
    "ggandor/leap.nvim",
    dependencies = { "tpope/vim-repeat" },
    opts = {
      max_highlighted_traversal_targets = 10,
      special_keys = {
        next_target = "<enter>",
        prev_target = "<tab>",
        next_group = "<space>",
        prev_group = "<tab>",
      },
    },
  },
}
