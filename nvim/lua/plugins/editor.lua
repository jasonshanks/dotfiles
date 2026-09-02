-- ✏️ Editor: core editing enhancements — motion, search, navigation, and text manipulation

return {
  {
    "folke/flash.nvim",
    -- enabled = false,
    ---@type Flash.Config
    opts = {},
    -- NOTE: the plugin option to enable char mode (replacing core f/F/t/T find commands with Flash would not work. The following function forces key overrides to load first.
    config = function(_, opts)
      require("flash").setup(opts)
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
    end,
    -- stylua: ignore
    keys = {
      { "s", false },
      { "S", false },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },

  {
    "yousefhadder/markdown-plus.nvim",
    ft = "markdown",
    opts = {},
  },

  -- disable mini.pairs
  { "nvim-mini/mini.pairs", enabled = false },

  {
    "nvim-mini/mini.surround",
    version = false,
    opts = {
      mappings = {
        add = "sa",
        delete = "sd",
        find = "sf",
        find_left = "sF",
        highlight = "sh",
        replace = "sr",
        update_n_lines = "sn",
      },
    },
  },

  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },

  -- Herdr/Nvim Navigation
  {
    "aimdevlee/herdr-nvim-nav",
    dependencies = { "christoomey/vim-tmux-navigator" }, -- omit if with_tmux = false
    config = function()
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
    end,
  },

  -- Create annotations with one keybind, and jump your cursor in the inserted annotation
  {
    "danymat/neogen",
    keys = {
      {
        "<leader>cc",
        function()
          require("neogen").generate({})
        end,
        desc = "Neogen Comment",
      },
    },
    opts = { snippet_engine = "luasnip" },
  },

  -- Refactoring tool
  {
    "ThePrimeagen/refactoring.nvim",
    keys = {
      {
        "<leader>r",
        function()
          require("refactoring").select_refactor()
        end,
        mode = "v",
        noremap = true,
        silent = true,
        expr = false,
      },
    },
    opts = {},
  },

  -- Go forward/backward with square brackets
  {
    "nvim-mini/mini.bracketed",
    event = "BufReadPost",
    config = function()
      local bracketed = require("mini.bracketed")
      bracketed.setup({
        file = { suffix = "" },
        window = { suffix = "" },
        quickfix = { suffix = "" },
        yank = { suffix = "" },
        treesitter = { suffix = "n" },
      })
    end,
  },

  -- Better increase/decrease
  {
    "monaqa/dial.nvim",
    -- stylua: ignore
    keys = {
      { "<C-a>", function() return require("dial.map").inc_normal() end, expr = true, desc = "Increment" },
      { "<C-x>", function() return require("dial.map").dec_normal() end, expr = true, desc = "Decrement" },
    },
    config = function()
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
    end,
  },

  {
    "rmagatti/auto-session",
    lazy = false,
    opts = {
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
    },
  },
}
