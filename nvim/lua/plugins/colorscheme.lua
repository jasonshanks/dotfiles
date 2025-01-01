return {
  -- tokyo night
  -- {
  --   "folke/tokyonight.nvim",
  --   name = "tokyonight",
  --   lazy = false,
  --   priority = 1000,
  --   transparent = true,
  -- },

  -- solarized - osaka
  {
    "craftzdog/solarized-osaka.nvim",
    lazy = false,
    priority = 1000,
    opts = function()
      return {
        transparent = true,
      }
    end,
  },

  -- nightowl
  -- {
  --   "oxfist/night-owl.nvim",
  --   name = "nightowl",
  --   lazy = false,
  --   priority = 1000,
  --   transparent = true,
  -- },

  -- nightfly
  -- {
  --   "bluz71/vim-nightfly-guicolors",
  --   name = "nightfly",
  --   lazy = false,
  --   priority = 1000,
  --   transparent = true,
  -- },
  --
  -- nightfox
  -- {
  --   "EdenEast/nightfox.nvim",
  --   name = "nightfox",
  --   lazy = true,
  --   priority = 1000,
  --   opts = function()
  --     return {
  --       transparent = true,
  --     }
  --   end,
  --   styles = {
  --     comments = "italic",
  --     keywords = "bold",
  --     types = "italic,bold",
  --   },
  -- },

  -- cyberdream
  -- {
  --   "scottmckendry/cyberdream.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require("cyberdream").setup({
  --       -- Recommended - see "Configuring" below for more config options
  --       transparent = true,
  --       italic_comments = true,
  --       hide_fillchars = true,
  --       terminal_colors = true,
  --     })
  --     vim.cmd("colorscheme cyberdream") -- set the colorscheme
  --   end,
  -- },

  -- catppuccin
  -- {
  --   "catppuccin/nvim",
  --   name = "catppuccin",
  --   lazy = false,
  --   priority = 1000,
  -- },
}
