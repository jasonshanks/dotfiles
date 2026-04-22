return {
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
}