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

-- lines
opt.number = true -- show line numbers
opt.relativenumber = true -- use relative line numbers
opt.cursorline = true -- highlight current line
opt.wrap = false -- No Wrap lines

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

opt.backup = false -- do not create backups
opt.swapfile = false -- do not create swap files
opt.cmdheight = 0
opt.laststatus = 3
opt.showmode = false -- do not show current mode (Statusline handles this)
opt.ruler = false
opt.showcmd = false
opt.scrolloff = 10
opt.shell = "fish"
opt.backupskip = { "/tmp/*", "/private/tmp/*" }
opt.inccommand = "split"

-- editing
vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr-o:hor20,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor" -- sets cursor to block (normal mode), line (edit mode) and to always blink
opt.iskeyword:append("-") -- include - in words

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

-- Set up undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])

-- Add asterisks in block comments
opt.formatoptions:append({ "r" })

-- Session options
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

vim.cmd([[au BufNewFile,BufRead *.astro setf astro]])
vim.cmd([[au BufNewFile,BufRead Podfile setf ruby]])
