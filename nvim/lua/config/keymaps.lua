-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Do things without affecting the registers
keymap.set("n", "x", '"_x')
-- keymap.set("n", "<Leader>p", '"0p')
-- keymap.set("n", "<Leader>P", '"0P')
keymap.set("v", "<Leader>p", '"0p')
keymap.set("n", "<Leader>c", '"_c')
keymap.set("n", "<Leader>C", '"_C')
keymap.set("v", "<Leader>c", '"_c')
keymap.set("v", "<Leader>C", '"_C')
keymap.set("n", "<Leader>d", '"_d')
keymap.set("n", "<Leader>D", '"_D')
keymap.set("v", "<Leader>d", '"_d')
keymap.set("v", "<Leader>D", '"_D')

-- Increment/decrement
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- Delete a word backwards
keymap.set("n", "dw", 'vb"_d')

-- Select all
keymap.set("n", "<C-a>", "gg<S-v>G")

-- Save with root permission (not working for now)
--vim.api.nvim_create_user_command('W', 'w !sudo tee > /dev/null %', {})

-- Disable continuations
keymap.set("n", "<Leader>o", "o<Esc>^Da", opts)
keymap.set("n", "<Leader>O", "O<Esc>^Da", opts)

-- Jumplist
keymap.set("n", "<C-m>", "<C-i>", opts)

-- New tab
keymap.set("n", "te", ":tabedit")
keymap.set("n", "<tab>", ":tabnext<Return>", opts)
keymap.set("n", "<s-tab>", ":tabprev<Return>", opts)
-- Split window
keymap.set("n", "ss", ":split<Return>", opts)
keymap.set("n", "sv", ":vsplit<Return>", opts)
-- Move window
keymap.set("n", "sh", "<C-w>h")
keymap.set("n", "sk", "<C-w>k")
keymap.set("n", "sj", "<C-w>j")
keymap.set("n", "sl", "<C-w>l")

-- Resize window
keymap.set("n", "<C-w><left>", "<C-w><")
keymap.set("n", "<C-w><right>", "<C-w>>")
keymap.set("n", "<C-w><up>", "<C-w>+")
keymap.set("n", "<C-w><down>", "<C-w>-")

-- Vim-Tmux-Navigator window navigation
keymap.set("n", "<C-h>", ":TmuxNavigateLeft<CR>")
keymap.set("n", "<C-j>", ":TmuxNavigateDown<CR>")
keymap.set("n", "<C-k>", ":TmuxNavigateUp<CR>")
keymap.set("n", "<C-l>", ":TmuxNavigateRight<CR>")

-- Open a new Tmux pane below in the same directory
keymap.set("n", "<leader>t", ":silent !tmux split-window -c %:p:h<CR>", { silent = true })

-- Neovim Project Manager
keymap.set("n", "<leader>p", ":Telescope neovim-project discover<CR>")

-- Diagnostics
-- @TODO: if use this need a non-confliction keymapping with Vim/Tmux navigation
-- keymap.set("n", "<C-j>", function()
--    vim.diagnostic.goto_next()
-- end, opts)

-- @NOTE: interesting custom function from craftzdog. Assume this replaces all HEX colour codes in (CSS?) with HSL. Would prefer OKLCH
-- keymap.set("n", "<leader>r", function()
--    require("jason.hsl").replaceHexWithHSL()
-- end)

keymap.set("n", "<leader>i", function()
  require("jason.lsp").toggleInlayHints()
end)