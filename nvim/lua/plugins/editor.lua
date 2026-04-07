return {
  {
    "folke/flash.nvim",
    enabled = false,
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {},
  -- stylua: ignore
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
  },
  },

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
