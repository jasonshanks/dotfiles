return {
  {
    "saghen/blink.cmp",
    dependencies = {
      {
        "Exafunction/windsurf.nvim",
      },
    },
    opts = {
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "codeium" },
        providers = {
          codeium = { name = "Codeium", module = "codeium.blink", async = true },
        },
      },

      keymap = {
        preset = "default",
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      },
    },
  },
}
