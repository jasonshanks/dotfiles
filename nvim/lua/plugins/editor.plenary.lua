return {
  {
    "nvim-lua/plenary.nvim",
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
          vim.cmd("highlight NonText guibg=NONE ctermbg=NONE")
        end,
      })
    end,
  },
}
