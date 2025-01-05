return {
  -- Colorschemes
  {
    "EdenEast/nightfox.nvim",
    "tiagovla/tokyodark.nvim",
    "folke/tokyonight.nvim",
    "bluz71/vim-nightfly-colors",
    "Mofiqul/dracula.nvim",
    "marko-cerovac/material.nvim",
    "ofirgall/ofirkai.nvim",
    "navarasu/onedark.nvim",
    "rose-pine/neovim",
    "sainnhe/sonokai",
  },
  -- Themery colorscheme switcher
  {
    "zaldih/themery.nvim",
    lazy = false,
    config = function()
      require("themery").setup({
        themes = {
          {
            name = "Carbonfox",
            colorscheme = "carbonfox",
          },
          {
            name = "Catppuccin Mocha",
            colorscheme = "catppuccin-mocha",
          },
          {
            name = "Dracula",
            colorscheme = "dracula",
          },
          {
            name = "Material Deep Ocean",
            colorscheme = "material",
            before = [[
            vim.g.material_style = "deep ocean"
            ]],
          },
          {
            name = "Nightfly",
            colorscheme = "nightfly",
          },
          {
            name = "Ofirkai Dark Blue",
            colorscheme = "ofirkai-darkblue",
          },
          {
            name = "OneDark Deep",
            colorscheme = "onedark",
            before = [[
            style = 'deep'
            ]],
          },
          {
            name = "Rose Pine",
            colorscheme = "rose-pine",
            before = [[
            variant = "auto"
            dark_variant = "main"
            ]],
          },
          {
            name = "Solarized Osaka",
            colorscheme = "solarized-osaka",
          },
          {
            name = "Sonokai",
            colorscheme = "sonokai",
          },
          {
            name = "Tokyo Dark",
            colorscheme = "tokyodark",
          },
          {
            name = "Tokyo Night",
            colorscheme = "tokyonight",
          },
        },
        globalBefore = [[
          transparent = true
          styles = {
            sidebars = "transparent",
            floats = "transparent",
          }
        ]],
      })
    end,
  },
}
