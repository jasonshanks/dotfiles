-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set -- set abbreviation for cleaner config
local opts = { noremap = true, silent = true } -- noremap prevents recursive expansion (safe default) and silent suppresses command output (cleaner UX). must append `,opts` to apply.

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

-- Move lines up and down
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==")
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==")
vim.keymap.set("i", "<A-j>", "<Esc>:m .+1<CR>==gi")
vim.keymap.set("i", "<A-k>", "<Esc>:m .-2<CR>==gi")
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv")

-- Duplicate lines up and down
vim.keymap.set("n", "<A-J>", ":t.<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<A-K>", ":t-1<CR>", { noremap = true, silent = true })
vim.keymap.set("i", "<A-J>", "<C-o>:t.<CR>", { noremap = true, silent = true })
vim.keymap.set("i", "<A-K>", "<C-o>:t-1<CR>", { noremap = true, silent = true })
vim.keymap.set("v", "<A-J>", ":t-1<CR>gv", { noremap = true, silent = true })
vim.keymap.set("v", "<A-K>", ":t'><CR>gv", { noremap = true, silent = true })

-- Increment/decrement
-- map("n", "+", "<C-a>")
-- map("n", "-", "<C-x>")

-- Select all
map("n", "<C-a>", "gg<S-v>G")

-- Copy current file path
map("n", "<leader>yp", "<cmd>let @+ = expand('%')<CR>", { desc = "Copy relative file path" })
map("n", "<leader>yP", "<cmd>let @+ = expand('%:p')<CR>", { desc = "Copy absolute file path" })

-- Disable continuations
-- map("n", "<Leader>o", "o<Esc>^Da", opts)

map("n", "<Leader>O", "O<Esc>^Da", { desc = "Insert new blank line above" })

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

-- Undotree toggle
vim.cmd("packadd nvim.undotree")
vim.keymap.set("n", "<leader>u", function()
  require("undotree").open({
    command = math.floor(vim.api.nvim_win_get_width(0) / 3) .. "vnew",
  })
end, { desc = "[U]ndotree toggle" })

-- Marks
-- set these marks to always be cross-buffer when lower-case.
map("n", "ma", "mA")
map("n", "'a", "'A")
map("n", "ms", "mS")
map("n", "'s", "'S")
map("n", "md", "mD")
map("n", "'d", "'D")

-- Jumplist
-- map("n", "<C-m>", "<C-i>", opts)

-- Quickfix list
map("n", "<M-n>", ":cnext<CR>zz", opts)
map("n", "<M-p>", ":cprev<CR>zz", opts)

-- Restart Neovim
map("n", "<leader>rr", ":restart<CR>", opts)

-- SUPER Quit: quit and delete all buffers
map("c", "Q", "%bd | qa", opts)

-- Diagnostics
-- @TODO: if use this need a non-confliction keymapping with Vim/Tmux navigation
-- map("n", "<C-j>", function()
--    vim.diagnostic.goto_next()
-- end, opts)
