-- Autocmds are loaded after options and keymaps.

local tmux = require("utils.tmux")

-- ============================================================================
-- TABLINE CUSTOM APPEAREANCE (updates on colorscheme changes)
-- ============================================================================

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "TabLine", { link = "StatusLineNC" })
    vim.api.nvim_set_hl(0, "TabLineSel", { link = "StatusLine" })
    vim.api.nvim_set_hl(0, "TabLineFill", { link = "Normal" })
  end,
})

-- ============================================================================
-- EDITOR BEHAVIOR AUTOCOMMANDS
-- ============================================================================

-- Create autocommand group for general editor behavior
vim.api.nvim_create_augroup("EditorBehavior", { clear = true })

-- Automatically disable paste mode when leaving insert mode
-- This prevents paste mode from staying enabled accidentally, which can cause
-- issues with autoindentation and other insert mode features
vim.api.nvim_create_autocmd("InsertLeave", {
  group = "EditorBehavior",
  pattern = "*",
  command = "set nopaste",
  desc = "Disable paste mode when leaving insert mode",
})

-- Clean up swap files automatically on successful write
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*",
  callback = function()
    -- Only remove swap if Vim reports no swap file in use
    if vim.fn.getbufvar(vim.fn.bufnr("%"), "&swapfile") == 0 then
      return
    end
    local file_path = vim.fn.expand("<afile>:p")
    -- Use Vim's built-in function to get the exact swap file path
    local swap_file = vim.fn.swapname(file_path)
    if swap_file ~= "" and vim.fn.filereadable(swap_file) == 1 then
      -- Notification when swap file deleted.
      -- vim.notify("Removing swap file: " .. swap_file, vim.log.levels.INFO)
      os.remove(swap_file)
    end
  end,
})

--  Enable Relative line numbers only in Visual modes
--  to default to all modes, comment this out and ensure relativenumber is uncommented in [nvim/lua/config/options.lua]
-- vim.api.nvim_create_autocmd("ModeChanged", {
--   pattern = "*:*v", -- Triggered when entering any visual mode
--   callback = function()
--     if vim.fn.mode():find("[vV\022]") then -- Check for visual modes (v, V, or Ctrl-V)
--       vim.opt.relativenumber = true
--     end
--   end,
-- })
--
-- vim.api.nvim_create_autocmd("ModeChanged", {
-- --   pattern = "*:[^v]*", -- Triggered when leaving visual modes
--   callback = function()
--     vim.opt.relativenumber = false
--   end,
-- })

-- ============================================================================
-- FILE TYPE SPECIFIC AUTOCOMMANDS
-- ============================================================================

-- Create autocommand group for file type specific configurations
vim.api.nvim_create_augroup("FileTypeConfig", { clear = true })

-- Disable concealing for JSON files to improve readability
-- LazyVim sets conceallevel=3 by default, but for JSON files it's better
-- to see the actual quotes and brackets for debugging and editing
vim.api.nvim_create_autocmd("FileType", {
  group = "FileTypeConfig",
  pattern = { "json", "jsonc" },
  callback = function()
    vim.opt.conceallevel = 0
  end,
  desc = "Disable concealing in JSON files for better readability",
})

-- ============================================================================
-- TMUX INTEGRATION AUTOCOMMANDS
-- ============================================================================

-- Create autocommand group for tmux-related functionality
vim.api.nvim_create_augroup("TmuxIntegration", { clear = true })

-- Initialize tmux mouse state tracking
vim.g.tmux_mouse_enabled = false

-- Disable tmux mouse when entering Neovim
-- This prevents the Neovim session from scrolling out of view in tmux
vim.api.nvim_create_autocmd("VimEnter", {
  group = "TmuxIntegration",
  callback = function()
    tmux.disable()
    -- Schedule another call as a safety measure in case the first one fails
    vim.schedule(tmux.disable)
  end,
  desc = "Disable tmux mouse and reduce history limit when entering Neovim",
})

-- Re-enable tmux mouse when leaving Neovim
-- This restores normal tmux behavior after Neovim exits
vim.api.nvim_create_autocmd("VimLeave", {
  group = "TmuxIntegration",
  callback = tmux.enable,
  desc = "Re-enable tmux mouse and restore history limit when leaving Neovim",
})

-- Initialize tmux settings immediately when this config loads
tmux.disable()

-- ============================================================================
-- USER COMMANDS
-- ============================================================================

-- Create a user command to manually toggle tmux mouse support
-- Useful for debugging or when you need to temporarily change the behavior
vim.api.nvim_create_user_command("ToggleTmuxMouse", function()
  local success = tmux.set(not tmux.enabled())
  if success then
    local state = tmux.enabled() and "enabled" or "disabled"
    vim.notify("Tmux mouse " .. state, vim.log.levels.INFO)
  end
end, {
  desc = "Toggle tmux mouse support and history limit",
})
