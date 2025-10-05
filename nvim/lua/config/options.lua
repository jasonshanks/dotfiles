-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- LazyVim root dir detection
vim.g.root_spec = { { ".git", "cwd" } }

local opt = vim.opt -- sets an alias of opt to the full vim.opt prefix for conciseness

-- encoding
vim.scriptencoding = "utf-8"
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"

-- line numbers
opt.number = true
opt.relativenumber = true

opt.title = true

-- tabs & indentation
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.autoindent = true -- copy indent from current line when starting new
opt.smartindent = true
opt.breakindent = true
opt.expandtab = true -- expand tab to spaces
opt.smarttab = true
opt.shiftwidth = 2 -- 2 spaces for indent

-- Fold configuration
opt.foldmethod = "indent" -- fold only where code is indented by spaces/tabs (assumes code is well formatted)
opt.foldnestmax = 1 -- folds at the first indentation level, only folding functions (not loops or conditionals inside functions)
opt.foldopen = "" -- these block auto-folding behaviour based on code navigation such as (search, quickfix, jumps, etc.)
opt.foldclose = ""

-- search settings
opt.hlsearch = true
opt.ignorecase = true -- Case insensitive searching UNLESS /C or capital in search
opt.smartcase = true -- if you include mixed case in your search, it will become case-sensitive

opt.backup = false
opt.cmdheight = 0
opt.laststatus = 3
opt.showmode = false
opt.ruler = false
opt.showcmd = false
opt.scrolloff = 10
opt.shell = "fish"
opt.backupskip = { "/tmp/*", "/private/tmp/*" }
opt.inccommand = "split"
opt.wrap = false -- No Wrap lines

-- backspace
opt.backspace = { "start", "eol", "indent" } -- allow backspace on indent, end of line or insert mode start position

opt.path:append({ "**" }) -- Finding files - Search down into subfolders
opt.wildignore:append({ "*/node_modules/*" })

-- Windows
opt.splitbelow = true -- Put new windows below current
opt.splitright = true -- Put new windows right of current
opt.splitkeep = "cursor"
opt.mouse = ""

-- Colors
opt.termguicolors = true
opt.background = "dark" -- colorschemes that are dark or light will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- Undercurl
-- Enable cursorline highlight
vim.opt.cursorline = true

-- Set up undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])

-- Add asterisks in block comments
opt.formatoptions:append({ "r" })

-- LSP Logs
vim.lsp.set_log_level("warn") -- or "error" for even less logging
-- Default is "info" which can be quite verbose

-- Session options
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

vim.cmd([[au BufNewFile,BufRead *.astro setf astro]])
vim.cmd([[au BufNewFile,BufRead Podfile setf ruby]])
