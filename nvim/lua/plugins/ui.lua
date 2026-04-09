return {
  -- messages, cmdline and the popupmenu
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

  -- buffer line
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
        -- separator_style = "slant",
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    },
  },

  -- statusline
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Custom Lualine component to show attached language server
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

      opts.options = {
        theme = "auto",
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      }

      -- Left sections (lualine_a, lualine_b, lualine_c)
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

      -- custom filename alternative including filetype and relative pathname
      -- local LazyVim = require("lazyvim.util")
      -- opts.sections.lualine_c[4] = {
      -- LazyVim.lualine.pretty_path({
      --   length = 0,
      --   relative = "cwd",
      --   modified_hl = "MatchParen",
      --   directory_hl = "",
      --   filename_hl = "Bold",
      --   modified_sign = "",
      --   readonly_icon = " 󰌾 ",
      -- }),
      -- }

      -- Right sections (lualine_x, lualine_y, lualine_z)
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

  {
    "folke/twilight.nvim",
    opts = {
      dimming = {
        alpha = 0.25, -- amount of dimming
        -- we try to get the foreground from the highlight groups or fallback color
        color = { "Normal", "#ffffff" },
        term_bg = "#000000", -- if guibg=NONE, this will be used to calculate text color
        inactive = false, -- when true, other windows will be fully dimmed (unless they contain the same buffer)
      },
      context = 10, -- amount of lines we will try to show around the current line
      treesitter = true, -- use treesitter when available for the filetype
      -- treesitter is used to automatically expand the visible text,
      -- but you can further control the types of nodes that should always be fully expanded
      expand = { -- for treesitter, we we always try to expand to the top-most ancestor with these types
        "function",
        "method",
        "table",
        "if_statement",
      },
      exclude = {}, -- exclude these filetypes
    },
  },
}
