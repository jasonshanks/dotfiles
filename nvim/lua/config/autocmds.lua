-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

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
      vim.notify("Removing swap file: " .. swap_file, vim.log.levels.INFO)
      os.remove(swap_file)
    end
  end,
})

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

-- Tmux mouse and history management functions
-- These functions control tmux mouse support and history limit to prevent
-- Neovim content from scrolling out of the tmux viewport

local function set_tmux_mouse(enabled)
  -- Only proceed if we're running inside a tmux session
  if not vim.env.TMUX then
    return false
  end

  local mouse_option = enabled and "on" or "off"
  local history_limit = enabled and "10000" or "1"

  -- Execute tmux commands and check for errors
  vim.fn.system("tmux set-option -g mouse " .. mouse_option)
  local mouse_error = vim.v.shell_error

  vim.fn.system("tmux set-option -g history-limit " .. history_limit)
  local history_error = vim.v.shell_error

  -- Report any errors to the user
  if mouse_error ~= 0 or history_error ~= 0 then
    vim.notify("Failed to configure tmux options", vim.log.levels.WARN)
    return false
  end

  vim.g.tmux_mouse_enabled = enabled
  return true
end

local function disable_tmux_mouse()
  return set_tmux_mouse(false)
end

local function enable_tmux_mouse()
  return set_tmux_mouse(true)
end

-- Disable tmux mouse when entering Neovim
-- This prevents the Neovim session from scrolling out of view in tmux
vim.api.nvim_create_autocmd("VimEnter", {
  group = "TmuxIntegration",
  callback = function()
    disable_tmux_mouse()
    -- Schedule another call as a safety measure in case the first one fails
    vim.schedule(disable_tmux_mouse)
  end,
  desc = "Disable tmux mouse and reduce history limit when entering Neovim",
})

-- Re-enable tmux mouse when leaving Neovim
-- This restores normal tmux behavior after Neovim exits
vim.api.nvim_create_autocmd("VimLeave", {
  group = "TmuxIntegration",
  callback = enable_tmux_mouse,
  desc = "Re-enable tmux mouse and restore history limit when leaving Neovim",
})

-- Initialize tmux settings immediately when this config loads
disable_tmux_mouse()

-- ============================================================================
-- USER COMMANDS
-- ============================================================================

-- Create a user command to manually toggle tmux mouse support
-- Useful for debugging or when you need to temporarily change the behavior
vim.api.nvim_create_user_command("ToggleTmuxMouse", function()
  local success = set_tmux_mouse(not vim.g.tmux_mouse_enabled)
  if success then
    local state = vim.g.tmux_mouse_enabled and "enabled" or "disabled"
    vim.notify("Tmux mouse " .. state, vim.log.levels.INFO)
  end
end, {
  desc = "Toggle tmux mouse support and history limit",
})
