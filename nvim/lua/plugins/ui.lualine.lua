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

return {
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
}