-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Turn off paste mode when leaving insert
vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  command = "set nopaste",
})

-- Disable the concealing in some file formats
-- The default conceallevel is 3 in LazyVim
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "json", "jsonc" },
  callback = function()
    vim.opt.conceallevel = 0
  end,
})

-- Disables tmux buffer scrollback so the neovim session doesn't scroll out of the viewport
vim.api.nvim_create_augroup("TmuxMouse", { clear = true })

-- Initialize the global variable
vim.g.tmux_mouse_enabled = false

local function set_tmux_mouse(enabled)
  if vim.env.TMUX then
    local mouse_option = enabled and "on" or "off"
    local history_limit = enabled and "10000" or "1"
    vim.fn.system("tmux set-option -g mouse " .. mouse_option)
    vim.fn.system("tmux set-option -g history-limit " .. history_limit)
    vim.g.tmux_mouse_enabled = enabled
    print("Tmux mouse " .. (enabled and "enabled" or "disabled")) -- Debug print
  end
end

local function disable_tmux_mouse()
  set_tmux_mouse(false)
end

local function enable_tmux_mouse()
  set_tmux_mouse(true)
end

-- Run immediately
disable_tmux_mouse()

-- Also set up autocommands for redundancy
vim.api.nvim_create_autocmd("VimEnter", {
  group = "TmuxMouse",
  callback = function()
    disable_tmux_mouse()
    -- Schedule another call just in case
    vim.schedule(disable_tmux_mouse)
  end,
})

vim.api.nvim_create_autocmd("VimLeave", {
  group = "TmuxMouse",
  callback = enable_tmux_mouse,
})

-- Add a user command to toggle tmux mouse manually
vim.api.nvim_create_user_command("ToggleTmuxMouse", function()
  set_tmux_mouse(not vim.g.tmux_mouse_enabled)
end, {})
