--------------------------------------------------------------------------------
-- 🎨 UI: visual presentation, aesthetics, and navigational feedback
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Colorscheme plugin specs + background/transparency toggle utilities
--------------------------------------------------------------------------------

-- Background Toggle Module
local M = {}

-- Single source of truth for background state: "transparent" | "black" | "default"
local bg_state = "default"

-- Highlight groups that receive a background override
local BG_HIGHLIGHT_GROUPS = {
  "Normal",
  "NormalFloat",
  "NormalNC",
  "SignColumn",
  "EndOfBuffer",
}

-- Colorschemes excluded from the custom picker
local EXCLUDED_COLORSCHEMES = {
  -- Vim built-ins
  "blue",
  "darkblue",
  "default",
  "delek",
  "desert",
  "elflord",
  "evening",
  "habamax",
  "industry",
  "koehler",
  "lunaperche",
  "morning",
  "murphy",
  "pablo",
  "peachpuff",
  "quiet",
  "retrobox",
  "ron",
  "shine",
  "slate",
  "sorbet",
  "torte",
  "unokai",
  "vim",
  "zaibatsu",
  "zellner",
  -- Light / unwanted variants of installed themes
  "bamboo-light",
  "bamboo-multiplex",
  "bamboo-vulgaris",
  "bluloco-dark",
  "bluloco-light",
  "dawnfox",
  "dayfox",
  "kanso-ink",
  "kanso-zen",
  "kanso-mist",
  "kanso-pearl",
  "kanagawa-dragon",
  "kanagawa-lotus",
  "kanagawa-wave",
  "material-lighter",
  "material-darker",
  "material-oceanic",
  "material-palenight",
  "ofirkai-darkblue",
  "onedark",
  "onelight",
  "rose-pine-dawn",
  "rose-pine-main",
  "solarized-osaka-day",
}

--- Apply highlight groups for a given background colour value.
--- Pass "NONE" for transparent or a hex string (e.g. "#000000") for a solid colour.
---@param bg string
local function set_bg_highlights(bg)
  for _, group in ipairs(BG_HIGHLIGHT_GROUPS) do
    vim.api.nvim_set_hl(0, group, { bg = bg })
  end
  vim.api.nvim_set_hl(0, "CursorLine", { blend = 50 })
end

--- Apply the current bg_state to Neovim highlight groups.
local function apply_background_state()
  if bg_state == "transparent" then
    set_bg_highlights("NONE")
  elseif bg_state == "black" then
    set_bg_highlights("#000000")
  else
    -- Restore the active colorscheme's default background
    local current_scheme = vim.g.colors_name or "default"
    if current_scheme ~= "default" then
      pcall(vim.cmd, "colorscheme " .. current_scheme)
    end
    -- Reset CursorLine to theme default
    vim.api.nvim_set_hl(0, "CursorLine", {})
  end
end

--- Return only user-installed colorschemes, filtering out built-ins and light variants.
---@return string[]
M.get_custom_colorschemes = function()
  local filtered = {}
  for _, color in ipairs(vim.fn.getcompletion("", "color")) do
    if not vim.tbl_contains(EXCLUDED_COLORSCHEMES, color) then
      table.insert(filtered, color)
    end
  end
  return filtered
end

--- Open a picker for user-installed colorschemes and apply the selection.
M.pick_colorscheme = function()
  vim.ui.select(M.get_custom_colorschemes(), { prompt = "Select colorscheme:" }, function(choice)
    if choice then
      vim.cmd("colorscheme " .. choice)
      apply_background_state()
      vim.notify("Colorscheme changed to " .. choice, vim.log.levels.INFO)
    end
  end)
end

--- Toggle transparent background on/off.
M.toggle_transparency = function()
  bg_state = (bg_state == "transparent") and "default" or "transparent"
  apply_background_state()
  vim.notify("Background set to " .. bg_state, vim.log.levels.INFO)
end

--- Toggle solid black background on/off.
M.toggle_black_background = function()
  bg_state = (bg_state == "black") and "default" or "black"
  apply_background_state()
  vim.notify("Background set to " .. bg_state, vim.log.levels.INFO)
end

--- Reset background to the active colorscheme's default.
M.reset_background = function()
  bg_state = "default"
  apply_background_state()
  vim.notify("Background reset to default", vim.log.levels.INFO)
end

--- Initialise the module: reset state after colorscheme loading completes.
M.init = function()
  bg_state = "default"
  vim.schedule(apply_background_state)
end

-- Keymaps
local keymap_opts = { noremap = true, silent = true }

vim.keymap.set(
  "n",
  "<leader>ct",
  M.toggle_transparency,
  vim.tbl_extend("force", keymap_opts, { desc = "Toggle transparency" })
)
vim.keymap.set(
  "n",
  "<leader>cb",
  M.toggle_black_background,
  vim.tbl_extend("force", keymap_opts, { desc = "Toggle black background" })
)
vim.keymap.set(
  "n",
  "<leader>cr",
  M.reset_background,
  vim.tbl_extend("force", keymap_opts, { desc = "Reset to default background" })
)
vim.keymap.set(
  "n",
  "<leader>cp",
  M.pick_colorscheme,
  vim.tbl_extend("force", keymap_opts, { desc = "Pick colorscheme (filtered)" })
)

-- Global accessor (intentional — allows access from other config files)
_G.ColorschemeTransparency = M

M.init()

-- ---------------------------------------------------------------------------
-- Helper: LSP client list for lualine
-- ---------------------------------------------------------------------------
local clients_lsp = function()
  local clients = vim.lsp.get_clients()
  if next(clients) == nil then
    return ""
  end

  local c = {}
  for _, client in pairs(clients) do
    table.insert(c, client.name)
  end
  return " " .. table.concat(c, "|")
end

--------------------------------------------------------------------------------
-- Colorschemes
--------------------------------------------------------------------------------
return {
  "ofirgall/ofirkai.nvim",
  "craftzdog/solarized-osaka.nvim",
  "bluz71/vim-moonfly-colors",
  "marko-cerovac/material.nvim",
  "EdenEast/nightfox.nvim",
  "ayu-theme/ayu-vim",
  "bluz71/vim-nightfly-colors",
  "folke/tokyonight.nvim",
  "rose-pine/neovim",
  "Mofiqul/dracula.nvim",
  "ribru17/bamboo.nvim",
  {
    "uloco/bluloco.nvim",
    lazy = false,
    priority = 1000,
    dependencies = { "rktjmp/lush.nvim" },
  },
  "rebelot/kanagawa.nvim",
  "vague2k/vague.nvim",
  "tyrannicaltoucan/vim-deep-space",
  "webhooked/kanso.nvim",
  "olimorris/onedarkpro.nvim",
  "NLKNguyen/papercolor-theme",
  "sainnhe/sonokai",
  "kamwitsta/vinyl.nvim",

  --------------------------------------------------------------------------------
  -- Buffer line
  --------------------------------------------------------------------------------
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
      { "<Tab>", "<Cmd>BufferLineCycleNext<CR>", desc = "Next tab" },
      { "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Prev tab" },
    },
    opts = {
      options = {
        mode = "tabs",
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    },
  },

  --------------------------------------------------------------------------------
  -- Cellular Automaton: a totally frivolous animation of current buffer contents. Like a fidget toy for your code!
  --------------------------------------------------------------------------------
  {
    "eandrju/cellular-automaton.nvim",

    vim.keymap.set("n", "<leader>fml", "<cmd>CellularAutomaton make_it_rain<CR>"),
    vim.keymap.set("n", "<leader>fmg", "<cmd>CellularAutomaton game_of_life<CR>"),
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      opts.options = {
        theme = "auto",
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      }

      opts.sections.lualine_a = {
        { "mode" },
      }

      opts.sections.lualine_b = {
        { "diagnostics" },
        { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
        {
          "filename",
          file_status = true,
          path = 1,
          symbols = { modified = "", readonly = " 󰌾 " },
          padding = { left = 0, right = 1 },
        },
      }

      opts.sections.lualine_c = {}

      opts.sections.lualine_x = { clients_lsp }

      opts.sections.lualine_y = {
        { "branch", icon = "" },
        {
          "diff",
          symbols = {
            added = "+",
            modified = "~",
            removed = "-",
          },
          padding = { left = 0, right = 2 },
        },
      }

      opts.sections.lualine_z = {
        { "progress", icon = "", padding = { left = 0, right = 0 } },
        { "location" },
      }
    end,
  },

  -- animations
  {
    "nvim-mini/mini.animate",
    event = "VeryLazy",
    opts = function(_, opts)
      opts.scroll = {
        enable = false,
      }
    end,
  },

  {
    "folke/noice.nvim",
    opts = function(_, opts)
      opts.views = vim.tbl_deep_extend("force", opts.views or {}, {
        cmdline_popup = {
          position = {
            row = "40%",
            col = "50%",
          },
          size = {
            width = 60,
            height = "auto",
          },
          border = {
            style = "none",
            padding = { 1, 2 },
          },
          filter_options = {},
          win_options = {
            winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
          },
        },
      })

      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "No information available",
        },
        opts = { skip = true },
      })

      local focused = true
      vim.api.nvim_create_autocmd("FocusGained", {
        callback = function()
          focused = true
        end,
      })
      vim.api.nvim_create_autocmd("FocusLost", {
        callback = function()
          focused = false
        end,
      })
      table.insert(opts.routes, 1, {
        filter = {
          cond = function()
            return not focused
          end,
        },
        view = "notify_send",
        opts = { stop = false },
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(event)
          vim.schedule(function()
            require("noice.text.markdown").keys(event.buf)
          end)
        end,
      })
    end,
  },

  {
    "folke/twilight.nvim",
    opts = {
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
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
}
