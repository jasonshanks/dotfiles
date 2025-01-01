return {
  -- Colorschemes
  {
    "EdenEast/nightfox.nvim",
    "tiagovla/tokyodark.nvim",
    "loctvl842/monokai-pro.nvim",
    "bluz71/vim-nightfly-colors",
    "Mofiqul/dracula.nvim",
    "marko-cerovac/material.nvim",
    "ofirgall/ofirkai.nvim",
    "navarasu/onedark.nvim",
    "rebelot/kanagawa.nvim",
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
            name = "Kanagawa",
            colorscheme = "kanagawa",
            before = [[
            theme = "wave" 
            background = {         
              dark = "dragon",     
              light = "lotus"
            }
            ]],
          },
          {
            name = "Material Deep Ocean",
            colorscheme = "material",
            before = [[
            vim.g.material_style = "deep ocean"
            ]],
          },
          {
            name = "Monokai Pro",
            colorscheme = "monokai-pro",
            before = [[
            filter = "octagon"
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
        },
      })
    end,
  },
}
