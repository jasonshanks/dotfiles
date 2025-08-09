-- Simplified transparency and background toggle
local M = {}
local bg_transparent = false
local bg_black = false

-- Apply background state (transparent, black, or default)
local function apply_background_state()
  if bg_transparent then
    -- Transparent background
    vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE" })
    return "transparent"
  elseif bg_black then
    -- Black background
    vim.api.nvim_set_hl(0, "Normal", { bg = "#000000" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#000000" })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "#000000" })
    vim.api.nvim_set_hl(0, "SignColumn", { bg = "#000000" })
    vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "#000000" })
    return "black"
  else
    -- Default colorscheme background
    local current_scheme = vim.g.colors_name or "default"
    if current_scheme ~= "default" then
      pcall(vim.cmd, "colorscheme " .. current_scheme)
    end
    return "default"
  end
end

M.toggle_transparency = function()
  bg_transparent = not bg_transparent
  if bg_transparent then
    bg_black = false -- Disable black when enabling transparency
  end

  local state = apply_background_state()
  print("Background set to " .. state)
end

M.toggle_black_background = function()
  bg_black = not bg_black
  if bg_black then
    bg_transparent = false -- Disable transparency when enabling black
  end

  local state = apply_background_state()
  print("Background set to " .. state)
end

M.reset_background = function()
  bg_transparent = false
  bg_black = false
  local state = apply_background_state()
  print("Background reset to " .. state)
end

-- Force default background on initialization
M.init = function()
  bg_transparent = false
  bg_black = false
  -- Use vim.schedule to ensure this runs after colorscheme loading
  vim.schedule(function()
    apply_background_state()
  end)
end

-- Set up keymaps
vim.keymap.set("n", "<leader>tt", M.toggle_transparency, { desc = "Toggle transparency" })
vim.keymap.set("n", "<leader>tb", M.toggle_black_background, { desc = "Toggle black background" })
vim.keymap.set("n", "<leader>tr", M.reset_background, { desc = "Reset to default background" })

-- Make globally accessible
_G.ColorschemeTransparency = M

-- Initialize default state
M.init()

-- Simple colorscheme configurations
return {
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
  },
}
