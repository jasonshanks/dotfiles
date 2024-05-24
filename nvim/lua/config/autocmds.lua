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

-- Disable tmux mouse mode when entering nvim
vim.api.nvim_create_autocmd("VimEnter", {
  group = "TmuxMouse",
  pattern = "*",
  command = "silent !tmux setw -g mouse off; sleep 0; sleep 0.1",
})

-- Enable tmux mouse mode when leaving nvim
vim.api.nvim_create_autocmd("VimLeave", {
  group = "TmuxMouse",
  pattern = "*",
  command = "silent !tmux setw -g mouse on; sleep 0.1",
})
