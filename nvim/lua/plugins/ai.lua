return {
  {
    "Exafunction/windsurf.nvim",
    enabled = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      require("codeium").setup({
        enable_cmp_source = false,
      })
    end,
  },
  {
    "NickvanDyke/opencode.nvim",
    dependencies = {
      -- Recommended for `ask()` and `select()`.
      -- Required for default `toggle()` implementation.
      { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
    },
    config = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        -- Your configuration, if any — see `lua/opencode/config.lua`, or "goto definition".
      }

      -- Required for `opts.auto_reload`.
      vim.o.autoread = true
    end,

    keys = {
      {
        "<leader>ot",
        function()
          require("opencode").toggle()
        end,
        desc = "Toggle embedded opencode",
      },
      {
        "<leader>oa",
        function()
          require("opencode").ask("@cursor: ")
        end,
        desc = "Ask opencode",
        mode = "n",
      },
      {
        "<leader>oa",
        function()
          require("opencode").ask("@selection: ")
        end,
        desc = "Ask opencode about selection",
        mode = "v",
      },
      {
        "<leader>op",
        function()
          require("opencode").select_prompt()
        end,
        desc = "Select prompt",
        mode = { "n", "v" },
      },
      {
        "<leader>on",
        function()
          require("opencode").command("session_new")
        end,
        desc = "New session",
      },
      {
        "<leader>oy",
        function()
          require("opencode").command("messages_copy")
        end,
        desc = "Copy last message",
      },
      {
        "<S-C-u>",
        function()
          require("opencode").command("messages_half_page_up")
        end,
        desc = "Scroll messages up",
      },
      {
        "<S-C-d>",
        function()
          require("opencode").command("messages_half_page_down")
        end,
        desc = "Scroll messages down",
      },
    },
  },
}
