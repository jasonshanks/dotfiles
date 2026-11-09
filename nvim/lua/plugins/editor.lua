-- ✏️ Editor: core editing enhancements — motion, search, navigation, and text manipulation.

-- Flash: jump anywhere with labels.
require("flash").setup({})

vim.keymap.set({ "n", "x", "o" }, "f", function()
  require("flash").jump({ mode = "f" })
end, { desc = "Flash f" })
vim.keymap.set({ "n", "x", "o" }, "F", function()
  require("flash").jump({ mode = "F" })
end, { desc = "Flash F" })
vim.keymap.set({ "n", "x", "o" }, "t", function()
  require("flash").jump({ mode = "t" })
end, { desc = "Flash t" })
vim.keymap.set({ "n", "x", "o" }, "T", function()
  require("flash").jump({ mode = "T" })
end, { desc = "Flash T" })

vim.keymap.set("o", "r", function()
  require("flash").remote()
end, { desc = "Remote Flash" })
vim.keymap.set({ "o", "x" }, "R", function()
  require("flash").treesitter_search()
end, { desc = "Treesitter Search" })
vim.keymap.set("c", "<c-s>", function()
  require("flash").toggle()
end, { desc = "Toggle Flash Search" })

-- Markdown editing helpers.
require("markdown-plus").setup({})

-- Pairs
require("mini.pairs").setup()

-- Mini.diff
-- TODO: not working yet
require("mini.diff").setup({
  view = {
    -- show whole reference part above whole buffer part, as in `git diff`
    overlay_style = "hunk",
  },
  mappings = {
    -- Apply hunks inside a visual/operator region
    apply = "gh",

    -- Reset hunks inside a visual/operator region
    reset = "gH",
    -- same keymaps as codediff.nvim
    goto_next = "]c",
    goto_prev = "[c",
  },
})

-- Tabout
require("tabout").setup({
  tabkey = "<Tab>", -- key to trigger tabout, set to an empty string to disable
  backwards_tabkey = "<S-Tab>", -- key to trigger backwards tabout, set to an empty string to disable
  act_as_tab = true, -- shift content if tab out is not possible
  act_as_shift_tab = false, -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
  default_tab = "<C-t>", -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
  default_shift_tab = "<C-d>", -- reverse shift default action,
  enable_backwards = true, -- well ...
  completion = false, -- if the tabkey is used in a completion pum
  tabouts = {
    { open = "'", close = "'" },
    { open = '"', close = '"' },
    { open = "`", close = "`" },
    { open = "(", close = ")" },
    { open = "[", close = "]" },
    { open = "{", close = "}" },
  },
  ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
  exclude = {}, -- tabout will ignore these filetypes
})

-- Mini Surround
require("mini.surround").setup({
  mappings = {
    add = "sa",
    delete = "sd",
    find = "sf",
    find_left = "sF",
    highlight = "sh",
    replace = "sr",
    update_n_lines = "sn",
  },
})

-- Quicker (Quick Fix)
require("quicker").setup({})

-- Tmux/Nvim Navigation
-- vim-tmux-navigator sources its default mappings after init.lua; keep its
-- commands available without letting those mappings override our mux-aware maps.
vim.g.tmux_navigator_no_mappings = 1

vim.keymap.set("n", "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>")

-- Herdr/Nvim Navigation
require("herdr-nvim-nav").setup({
  with_tmux = nil, -- nil = auto-detect $TMUX; true/false to force
  keymaps = { -- lhs list per direction; {} disables a direction
    left = { "<C-h>", "<C-Left>" },
    down = { "<C-j>", "<C-Down>" },
    up = { "<C-k>", "<C-Up>" },
    right = { "<C-l>", "<C-Right>" },
  },
  socket_path = nil, -- default: $HERDR_SOCKET_PATH or ~/.config/herdr/herdr.sock
  cache_dir = nil, -- default: $XDG_CACHE_HOME or ~/.cache
  herdr_bin = nil, -- default: $HERDR_BIN_PATH or "herdr"
  socket_timeout_ms = 150,
})

-- TUIOS NVIM Navigator
require("tuios-nvim-navigator").setup()

-- REX NVIM Navigator
local rex_nav = require("rex-navigator")
rex_nav.setup({ keymaps = rex_nav.in_rex() })

-- Create annotations with one keybind, and jump your cursor in the inserted annotation
require("neogen").setup({ snippet_engine = "luasnip" })

vim.keymap.set("n", "<leader>cc", function()
  require("neogen").generate({})
end, { desc = "Neogen Comment" })

-- Refactoring tool
require("refactoring").setup({})

vim.keymap.set("v", "<leader>r", function()
  require("refactoring").select_refactor()
end, { noremap = true, silent = true, expr = false })

-- Go forward/backward with square brackets
local bracketed = require("mini.bracketed")
bracketed.setup({
  file = { suffix = "" },
  window = { suffix = "" },
  quickfix = { suffix = "" },
  yank = { suffix = "" },
  treesitter = { suffix = "n" },
})

-- Better increase/decrease
vim.keymap.set("n", "<C-a>", function()
  return require("dial.map").inc_normal()
end, { expr = true, desc = "Increment" })
vim.keymap.set("n", "<C-x>", function()
  return require("dial.map").dec_normal()
end, { expr = true, desc = "Decrement" })

local augend = require("dial.augend")
require("dial.config").augends:register_group({
  default = {
    augend.integer.alias.decimal,
    augend.integer.alias.hex,
    augend.date.alias["%Y/%m/%d"],
    augend.constant.alias.bool,
    augend.semver.alias.semver,
    augend.constant.new({ elements = { "let", "const" } }),
  },
})

-- Session restore
require("auto-session").setup({
  suppressed_dirs = { "~/", "~/Sites", "~/Downloads", "/" },
  pre_save_cmds = {
    "silent! %foldopen!", -- Open all folds before saving
    function()
      -- Reset all folds before saving
      pcall(vim.cmd, "silent! normal! zE")
    end,
  },
  pre_restore_cmds = {
    "silent! %foldopen!", -- Open all folds before restoring
  },
  post_restore_cmds = {
    function()
      -- Reset fold settings after restore
      pcall(function()
        vim.wo.foldlevel = 99 -- sessions save foldlevel, which may restore as 0 (all closed)
        vim.cmd("silent! normal! zN") -- ensure folding is on
        vim.cmd("silent! normal! zx") -- recompute folds
      end)
    end,
  },
  save_extra_cmds = {
    "set foldmethod?", -- save the fold method
    "set foldenable?", -- save fold enable state
  },
  -- log_level = 'debug',
})
