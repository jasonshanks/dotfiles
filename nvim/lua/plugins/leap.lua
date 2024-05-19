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
    vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap-forward)"),
    vim.keymap.set({ "n", "x", "o" }, "S", "<Plug>(leap-backward)"),
    vim.keymap.set({ "n", "x", "o" }, "gs", "<Plug>(leap-from-window)"),
  },
}
