return { -- FIX: this does nothing, but should override the default TAB behavior to cycle through autocompletion suggestions.
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    mapping = {
      ["<Tab>"] = function(fallback)
        if require("cmp").visible() then
          require("cmp").select_next_item()
        elseif require("luasnip").expandable() then
          require("luasnip").expand()
        elseif require("luasnip").expand_or_jumpable() then
          require("luasnip").expand_or_jump()
        else
          fallback()
        end
      end,
      ["<S-Tab>"] = function(fallback)
        if require("cmp").visible() then
          require("cmp").select_prev_item()
        elseif require("luasnip").jumpable(-1) then
          require("luasnip").jump(-1)
        else
          fallback()
        end
      end,
    },
  },
}
