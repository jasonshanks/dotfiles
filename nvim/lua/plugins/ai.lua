return {
  {
    "Exafunction/windsurf.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      require("codeium").setup({
        enable_cmp_source = false,
      })
    end,
  },
}
