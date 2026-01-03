-- Simplified transparency and background toggle
local M = {}
local bg_transparent = true
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

-- Get filtered colorschemes (excludes default vim themes)
M.get_custom_colorschemes = function()
  local all_colors = vim.fn.getcompletion("", "color")
  local excluded_defaults = {
    "blue",
    "darkblue",
    "default",
    "delek",
    "desert",
    "elflord",
    "evening",
    "habamax",
    "industry",
    "koehler",
    "lunaperche",
    "morning",
    "murphy",
    "pablo",
    "peachpuff",
    "quiet",
    "retrobox",
    "ron",
    "shine",
    "slate",
    "torte",
    "unokai",
    "vim",
    "zaibatsu",
    "zellner",
    -- Custom theme (light variations)
    "bamboo-light",
    "bamboo-multiplex",
    "bamboo-vulgaris",
    "bluloco-dark",
    "bluloco-light",
    "dawnfox",
    "dayfox",
    "onelight",
  }

  local filtered_colors = {}
  for _, color in ipairs(all_colors) do
    if not vim.tbl_contains(excluded_defaults, color) then
      table.insert(filtered_colors, color)
    end
  end

  return filtered_colors
end

-- Custom colorscheme picker that only shows your installed themes
M.pick_colorscheme = function()
  local colors = M.get_custom_colorschemes()
  vim.ui.select(colors, {
    prompt = "Select colorscheme:",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if choice then
      vim.cmd("colorscheme " .. choice)
      -- Reapply your background state
      apply_background_state()
      print("Colorscheme changed to " .. choice)
    end
  end)
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
vim.keymap.set("n", "<leader>ct", M.toggle_transparency, { desc = "Toggle transparency" })
vim.keymap.set("n", "<leader>cb", M.toggle_black_background, { desc = "Toggle black background" })
vim.keymap.set("n", "<leader>cr", M.reset_background, { desc = "Reset to default background" })
vim.keymap.set("n", "<leader>cp", M.pick_colorscheme, { desc = "Pick colorscheme (filtered)" })

-- Make globally accessible
_G.ColorschemeTransparency = M

-- Initialize default state
M.init()

-- Simple colorscheme configurations
return {
  "ofirgall/ofirkai.nvim",
  "craftzdog/solarized-osaka.nvim",
  "bluz71/vim-moonfly-colors",
  "marko-cerovac/material.nvim",
  "EdenEast/nightfox.nvim", -- carbonfox
  "ayu-theme/ayu-vim",
  "bluz71/vim-nightfly-colors",
  "folke/tokyonight.nvim",
  "rose-pine/neovim",
  "Mofiqul/dracula.nvim",
  "ribru17/bamboo.nvim",
  {
    "uloco/bluloco.nvim",
    lazy = false,
    priority = 1000,
    dependencies = { "rktjmp/lush.nvim" },
  },
  "rebelot/kanagawa.nvim",
  "vague2k/vague.nvim",
  "tyrannicaltoucan/vim-deep-space",
  "webhooked/kanso.nvim",
  "olimorris/onedarkpro.nvim",
  "NLKNguyen/papercolor-theme",
  "sainnhe/sonokai",
  "kamwitsta/vinyl.nvim",
}
