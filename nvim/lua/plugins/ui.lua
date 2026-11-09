--------------------------------------------------------------------------------
-- UI: colorscheme, statusline, pickers, notifications and other presentation.
--------------------------------------------------------------------------------

-- Active colorscheme: catppuccin-mocha. The VimEnter workaround below clears the
-- background of Normal/NonText so the terminal background shows through.
require("catppuccin").setup({})
vim.cmd.colorscheme("catppuccin-mocha")

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
    vim.cmd("highlight NonText guibg=NONE ctermbg=NONE")
  end,
})

-- Colorscheme picker + transparency / black background toggles.
require("utils.colorscheme")

-- Icons
require("mini.icons").setup()
require("mini.icons").mock_nvim_web_devicons()

-- Picker, notifications, dashboard, terminal, ...
require("snacks").setup({
  input = { enabled = true },
  image = {},
  picker = {
    enabled = true,
    matcher = {
      frecency = true,
    },
    sources = {
      files = { hidden = true },
      grep = { hidden = true },
    },
  },
  notifier = { enabled = true },
  statuscolumn = { enabled = true },
  words = { enabled = true },
  lazygit = {},
  terminal = {
    win = {
      position = "float", -- "float", "bottom", "top", "left", "right"
      height = 0.8, -- 80% of screen height
      width = 0.8, -- 80% of screen width
    },
  },

  -- convenience
  quickfile = {},

  ---@class snacks.zen.Config
  zen = {
    ---@type table<string, boolean>
    toggles = {
      dim = true,
      git_signs = false,
      mini_diff_signs = false,
      diagnostics = false,
      inlay_hints = false,
      line_number = false,
    },
    show = {
      statusline = false, -- can only be shown when using the global statusline
      tabline = false,
    },
    ---@type snacks.win.Config
    win = { style = "zen" },
    enabled = true,
    enter = true,
    fixbuf = false,
    minimal = false,
    width = 140,
    height = 0,
    backdrop = { transparent = true, blend = 0 },
    keys = { q = false },
    zindex = 40,
    wo = {
      winhighlight = "NormalFloat:Normal",
    },
    w = {
      snacks_main = true,
    },
    --- Options for the `Snacks.zen.zoom()`
    ---@type snacks.zen.Config
    zoom = {
      toggles = {},
      show = {
        statusline = true,
        tabline = true,
      },
      win = {
        backdrop = false,
        width = 0, -- full width
      },
    },
  },
})

-- Install the vim.ui adapters now instead of waiting for Snacks' UIEnter hook.
require("snacks.input").enable()
require("snacks.picker").setup()

-- Cellular Automaton: a totally frivolous animation of current buffer contents. Like a fidget toy for your code!
vim.keymap.set("n", "<leader>fml", "<cmd>CellularAutomaton make_it_rain<CR>")
vim.keymap.set("n", "<leader>fmg", "<cmd>CellularAutomaton game_of_life<CR>")

-- LSP client list for lualine
local clients_lsp = function()
  local clients = vim.lsp.get_clients()
  if next(clients) == nil then
    return ""
  end

  local c = {}
  for _, client in pairs(clients) do
    table.insert(c, client.name)
  end
  return "\239\128\147 " .. table.concat(c, "|")
end

require("lualine").setup({
  options = {
    theme = "auto",
    globalstatus = true,
    component_separators = { left = "", right = "" },
    section_separators = { left = "\238\130\180", right = "\238\130\182" },
  },
  sections = {
    lualine_a = {
      { "mode" },
    },
    lualine_b = {
      { "diagnostics" },
      { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
      {
        "filename",
        file_status = true,
        path = 1,
        symbols = { modified = "", readonly = " \243\176\140\190 " },
        padding = { left = 0, right = 1 },
      },
    },
    lualine_c = {},
    lualine_x = { clients_lsp },
    lualine_y = {
      { "branch", icon = "\238\156\165" },
      {
        "diff",
        symbols = {
          added = "+",
          modified = "~",
          removed = "-",
        },
        padding = { left = 0, right = 2 },
      },
    },
    lualine_z = {
      { "progress", icon = "\238\152\146", padding = { left = 0, right = 0 } },
      { "location" },
    },
  },
})

-- Animations
require("mini.animate").setup({
  scroll = {
    enable = false,
  },
})

-- Cmdline: tiny-cmdline.nvim repositions Neovim's ui2 cmdline as a centered,
-- borderless-looking float with blank-cell padding (see cmdline_pad).
-- Snacks still handles vim.ui.input.
-- Breathing room: tiny-cmdline has no padding option, and its height is the
-- input window's own line count. Instead, the frame
-- is a full 8-part border made of blank cells. Those cells take the float's
-- background, so the prompt looks borderless but gets one cell of space on each
-- side. Terminals size in cells, so this is ~1 column (≈8–10px) horizontally and
-- 1 row (≈16–22px) vertically.
local cmdline_pad = { " ", " ", " ", " ", " ", " ", " ", " " }

require("tiny-cmdline").setup({
  width = { value = 60, min = 40, max = 80 },
  -- Horizontally centred; vertically a little above centre (40% of the free space).
  position = { x = "50%", y = "40%" },
  border = cmdline_pad,
  -- Search stays at the bottom as before.
  native_types = { "/", "?" },
})

-- Keep the float colours tied to the active theme. Re-applied on every colorscheme change,
-- since :colorscheme clears highlight links.
local function tiny_cmdline_highlights()
  vim.api.nvim_set_hl(0, "TinyCmdlineNormal", { link = "NormalFloat" })
  vim.api.nvim_set_hl(0, "TinyCmdlineBorder", { link = "NormalFloat" })
end
tiny_cmdline_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = tiny_cmdline_highlights,
})

-- Dim the inactive parts of the buffer
require("twilight").setup({
  dimming = {
    alpha = 0.25,
    color = { "Normal", "#ffffff" },
    term_bg = "#000000",
    inactive = false,
  },
  context = 10,
  treesitter = true,
  expand = {
    "function",
    "method",
    "table",
    "if_statement",
  },
  exclude = {},
})

-- Keymap hints
require("which-key").setup({})

vim.keymap.set("n", "<leader>?", function()
  require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })
