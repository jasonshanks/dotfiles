return {
  -- Colorschemes
  {
    "folke/tokyonight.nvim",
    "EdenEast/nightfox.nvim",
    "bluz71/vim-nightfly-colors",
    "craftzdog/solarized-osaka.nvim",
    "rebelot/kanagawa.nvim",
    "webhooked/kanso.nvim",
    "tyrannicaltoucan/vim-deep-space",
    "ayu-theme/ayu-vim",
    "Mofiqul/dracula.nvim",
    "marko-cerovac/material.nvim",
    "ofirgall/ofirkai.nvim",
    "olimorris/onedarkpro.nvim",
    "NLKNguyen/papercolor-theme",
    "sainnhe/sonokai",
    "rose-pine/neovim",
    "vague2k/vague.nvim",
    "kamwitsta/vinyl.nvim",
    "ribru17/bamboo.nvim",
    {
      "uloco/bluloco.nvim",
      lazy = false,
      priority = 1000,
      dependencies = { "rktjmp/lush.nvim" },
      config = function()
        -- your optional config goes here, see below.
      end,
    },
  },
}
