-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

vim.g.mapleader = " "

-- Do things without affecting the registers
map("n", "x", '"_x')
-- map("n", "<Leader>p", '"0p')
-- map("n", "<Leader>P", '"0P')
map("v", "<Leader>p", '"0p')
map("n", "<Leader>c", '"_c')
map("n", "<Leader>C", '"_C')
map("v", "<Leader>c", '"_c')
map("v", "<Leader>C", '"_C')
map("n", "<Leader>d", '"_d')
map("n", "<Leader>D", '"_D')
map("v", "<Leader>d", '"_d')
map("v", "<Leader>D", '"_D')

-- Increment/decrement
-- map("n", "+", "<C-a>")
-- map("n", "-", "<C-x>")

-- Delete a word backwards
map("n", "dw", 'vb"_d')

-- Select all
map("n", "<C-a>", "gg<S-v>G")

-- Save with root permission (not working for now)
--vim.api.nvim_create_user_command('W', 'w !sudo tee > /dev/null %', {})

-- Disable continuations
-- map("n", "<Leader>o", "o<Esc>^Da", opts)
map("n", "<Leader>O", "O<Esc>^Da", opts)

-- New tab
-- map("n", "te", ":tabedit")
-- map("n", "<tab>", ":tabnext<Return>", opts)
-- map("n", "<s-tab>", ":tabprev<Return>", opts)

-- Resize window
map("n", "<M-k>", "<cmd>resize +6<CR>") -- increase height
map("n", "<M-j>", "<cmd>resize -2<CR>") -- decrease height
map("n", "<M-l>", "<cmd>vertical resize +5<CR>") -- increase width
map("n", "<M-h>", "<cmd>vertical resize -5<CR>") -- decrease width

-- Vertical scroll and center
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "<C-d>", "<C-d>zz", opts)

-- Jumplist
-- map("n", "<C-m>", "<C-i>", opts)

-- Quickfix list
map("n", "<M-n>", ":cnext<CR>zz", opts)
map("n", "<M-p>", ":cprev<CR>zz", opts)

-- SUPER Quit: quit and delete all buffers
map("c", "Q", "%bd | qa", opts)

-- Diagnostics
-- @TODO: if use this need a non-confliction keymapping with Vim/Tmux navigation
-- map("n", "<C-j>", function()
--    vim.diagnostic.goto_next()
-- end, opts)
