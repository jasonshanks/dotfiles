return {
  {
    "folke/snacks.nvim",

    ---@type snacks.Config
    opts = {
      dashboard = {
        preset = {
          header = [[
                                        oo            
                                                  
88d888b. .d8888b. .d8888b. dP   .dP dP 88d8b.d8b. 
88'  `88 88ooood8 88'  `88 88   d8' 88 88'`88'`88 
88    88 88.  ... 88.  .88 88 .88'  88 88  88  88 
dP    dP `88888P' `88888P' 8888P'   dP dP  dP  dP]],
          -- stylua: ignore
          ---@type snacks.dashboard.Item[]
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
      notifier = {
        enabled = true,
        --- available style: "compact"|"fancy"|"minimal"
        style = "compact",
      },
      statuscolumn = {
        enabled = true,
      },
      image = {},
      terminal = {
        -- win = { -- below is mostly default anyway but is currently being handled by edgy
        --   position = "bottom", -- or "bottom", "top", "left", "right"
        --   height = 0.3, -- 30% of screen height
        --   width = 1.0, -- 100% of screen width
        -- },
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

      -- integrations
      lazygit = {},
    },
  },
}
