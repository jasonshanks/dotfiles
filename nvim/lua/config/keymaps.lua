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
-- NOTE: below not needed with current usage of CTRL+vim bindings
-- keymap.set("n", "sh", "<C-w>h")
-- keymap.set("n", "sk", "<C-w>k")
-- keymap.set("n", "sj", "<C-w>j")
-- keymap.set("n", "sl", "<C-w>l")

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

-- PLUGINS

-- Oil
-- keymap.set("n", "<Leader>-", ":Oil<CR>")

-- Yazi
keymap.set("n", "-", "<cmd>Yazi<cr>") -- Open at the current file
keymap.set("n", "<Leader>cw", "<cmd>Yazi cwd<cr>") -- Open in the current working directory

-- Yanky
keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)")
keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)")

keymap.set("n", "<c-p>", "<Plug>(YankyPreviousEntry)")
keymap.set("n", "<c-n>", "<Plug>(YankyNextEntry)")

keymap.set("n", "]p", "<Plug>(YankyPutIndentAfterLinewise)")
keymap.set("n", "[p", "<Plug>(YankyPutIndentBeforeLinewise)")
keymap.set("n", "]P", "<Plug>(YankyPutIndentAfterLinewise)")
keymap.set("n", "[P", "<Plug>(YankyPutIndentBeforeLinewise)")

keymap.set("n", ">p", "<Plug>(YankyPutIndentAfterShiftRight)")
keymap.set("n", "<p", "<Plug>(YankyPutIndentAfterShiftLeft)")
keymap.set("n", ">P", "<Plug>(YankyPutIndentBeforeShiftRight)")
keymap.set("n", "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)")

keymap.set("n", "=p", "<Plug>(YankyPutAfterFilter)")
keymap.set("n", "=P", "<Plug>(YankyPutBeforeFilter)")

-- Diagnostics
-- @TODO: if use this need a non-confliction keymapping with Vim/Tmux navigation
-- keymap.set("n", "<C-j>", function()
--    vim.diagnostic.goto_next()
-- end, opts)

-- require("jason.lsp").toggleInlayHints()
-- keymap.set("n", "<leader>i", function() end)
