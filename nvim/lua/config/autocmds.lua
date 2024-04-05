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
  pattern = { "json", "jsonc", "markdown" },
  callback = function()
    vim.opt.conceallevel = 0
  end,
})

-- Set CWD for parent terminal (so tmux pane inherits what the current Neovim Project directory has been switched to)
-- @NOTE: WIP: not quite working yet
vim.api.nvim_create_autocmd({ "DirChanged" }, {
  pattern = "global",
  -- group = augroup,
  callback = function()
    --- actions to set CWD for parent terminal
    -- vim.fn.system("tmux set-environment -g TMUXPWD $(pwd)")
    os.execute("tmux set-environment -g TMUXPWD $" .. vim.fn.getcwd())
  end,
})
