return {
  "APZelos/blamer.nvim",
  config = function()
    vim.keymap.set("n", "<leader>gB", ":BlamerToggle<CR>")
  end,
}
