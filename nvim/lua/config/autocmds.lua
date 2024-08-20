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

local function disable_tmux_mouse()
  if vim.env.TMUX then
    vim.fn.system("tmux set-option -g mouse off")
    vim.fn.system("tmux set-option -g history-limit 1")
    print("Tmux mouse disabled") -- Debug print
  end
end

local function enable_tmux_mouse()
  if vim.env.TMUX then
    vim.fn.system("tmux set-option -g mouse on")
    vim.fn.system("tmux set-option -g history-limit 10000")
    print("Tmux mouse enabled") -- Debug print
  end
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
  if vim.g.tmux_mouse_enabled then
    disable_tmux_mouse()
    vim.g.tmux_mouse_enabled = false
  else
    enable_tmux_mouse()
    vim.g.tmux_mouse_enabled = true
  end
end, {})
