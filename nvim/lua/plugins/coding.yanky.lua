return {
  {
    "gbprod/yanky.nvim",
    keys = {
      -- Put mappings (normal and visual modes)
      { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put after" },
      { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put before" },
      { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put after and leave cursor" },
      { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put before and leave cursor" },

      -- Cycle through yank history
      { "<c-p>", "<Plug>(YankyPreviousEntry)", desc = "Previous yank" },
      { "<c-n>", "<Plug>(YankyNextEntry)", desc = "Next yank" },

      -- Put with indent (linewise)
      { "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put after with indent" },
      { "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put before with indent" },
      { "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put after with indent" },
      { "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put before with indent" },

      -- Put with shift
      { ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put after and shift right" },
      { "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put after and shift left" },
      { ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put before and shift right" },
      { "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put before and shift left" },

      -- Put with filter
      { "=p", "<Plug>(YankyPutAfterFilter)", desc = "Put after with filter" },
      { "=P", "<Plug>(YankyPutBeforeFilter)", desc = "Put before with filter" },
    },
    opts = {
      ring = {
        history_length = 100,
        storage = "shada",
        storage_path = vim.fn.stdpath("data") .. "/databases/yanky.db", -- Only for sqlite storage
        sync_with_numbered_registers = true,
        cancel_event = "update",
        ignore_registers = { "_" },
        update_register_on_cycle = false,
      },
      picker = {
        select = {
          action = nil, -- nil to use default put action
        },
      },
      system_clipboard = {
        sync_with_ring = true,
        clipboard_register = nil,
      },
      highlight = {
        on_put = true,
        on_yank = true,
        timer = 500,
      },
      preserve_cursor_position = {
        enabled = true,
      },
      textobj = {
        enabled = true,
      },
    },
  },
}
