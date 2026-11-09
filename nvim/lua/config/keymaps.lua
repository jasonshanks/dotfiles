-- Keymaps are loaded after options.

local map = vim.keymap.set -- set abbreviation for cleaner config
local opts = { noremap = true, silent = true } -- noremap prevents recursive expansion (safe default) and silent suppresses command output (cleaner UX). must append `,opts` to apply.

-- Local leader for filetype-scoped maps (LazyVim-compatible default).
vim.g.maplocalleader = "\\"

-- Better up/down: display-line movement unless a count is given.
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Escape clears the search highlight and stops a native snippet session.
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  if vim.snippet and vim.snippet.active() then
    vim.snippet.stop()
  end
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

-- Direction-aware search navigation (keeps the original direction on n/N).
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Add undo break-points at punctuation.
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- Save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- Keywordprg under the cursor
map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })

-- Better indenting (keep the selection)
map("x", "<", "<gv")
map("x", ">", ">gv")

-- Comment below/above (uses the built-in `gc` operator / ts-comments).
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

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
map("n", "<A-j>", ":m .+1<CR>==")
map("n", "<A-k>", ":m .-2<CR>==")
map("i", "<A-j>", "<Esc>:m .+1<CR>==gi")
map("i", "<A-k>", "<Esc>:m .-2<CR>==gi")
map("v", "<A-j>", ":m '>+1<CR>gv=gv")
map("v", "<A-k>", ":m '<-2<CR>gv=gv")

-- Duplicate lines up and down
map("n", "<A-J>", ":t.<CR>", { noremap = true, silent = true })
map("n", "<A-K>", ":t-1<CR>", { noremap = true, silent = true })
map("i", "<A-J>", "<C-o>:t.<CR>", { noremap = true, silent = true })
map("i", "<A-K>", "<C-o>:t-1<CR>", { noremap = true, silent = true })
map("v", "<A-J>", ":t-1<CR>gv", { noremap = true, silent = true })
map("v", "<A-K>", ":t'><CR>gv", { noremap = true, silent = true })

-- Increment/decrement
-- map("n", "+", "<C-a>")
-- map("n", "-", "<C-x>")

---------------------------------
-- Selection and Copy behaviour--
---------------------------------
map("n", "<C-a>", "gg<S-v>G") -- Select all
vim.opt.clipboard:append("unnamedplus") -- Use system clipboard

-- Copy current file path
-- map("n", "<leader>yp", "<cmd>let @+ = expand('%')<CR>", { desc = "Copy relative file path" })
-- map("n", "<leader>yP", "<cmd>let @+ = expand('%:p')<CR>", { desc = "Copy absolute file path" })
map("n", "<leader>yp", function()
  require("utils.editor").yank_relative_path_with_line()
end, { desc = "Yank relative path with line number" })
map("n", "<leader>yP", function()
  require("utils.editor").yank_absolute_path_with_line()
end, { desc = "Yank absolute path with line number" })

-- Copy as markdown code block
map(
  "v",
  "<leader>cc",
  ":<C-u>lua require('utils.editor').copy_as_codeblock()<CR>",
  { desc = "Copy as markdown code block" }
)

-- Disable continuations
-- map("n", "<Leader>o", "o<Esc>^Da", opts)

map("n", "<Leader>O", "O<Esc>^Da", { desc = "Insert new blank line above" })

-- windows
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

-- Resize window
map("n", "<M-k>", "<cmd>resize +6<CR>") -- increase height
map("n", "<M-j>", "<cmd>resize -2<CR>") -- decrease height
map("n", "<M-l>", "<cmd>vertical resize +5<CR>") -- increase width
map("n", "<M-h>", "<cmd>vertical resize -5<CR>") -- decrease width

-- tabs
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

-- Vertical scroll and center
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "<C-d>", "<C-d>zz", opts)

-- Undotree toggle
vim.cmd("packadd nvim.undotree")
vim.keymap.set("n", "<leader>uu", function()
  require("undotree").open({
    command = math.floor(vim.api.nvim_win_get_width(0) / 3) .. "vnew",
  })
end, { desc = "Toggle Undotree" })

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

-- Redraw / clear hlsearch / update diff
map(
  "n",
  "<leader>ur",
  "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / Clear hlsearch / Diff Update" }
)

-- Vim.pack (Update)
map("n", "<leader>l", function()
  vim.pack.update()
end, { desc = "Update Plugins" })

-- Restart
map("n", "<leader>rr", ":restart<CR>", opts)

-- Quit All
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

-- SUPER Quit: quit and delete all buffers
map("c", "Q", "%bd | qa", opts)
