-- 🛠️ Tools: file management, git integration and outlines.

local detail = false

-- File explorer
require("oil").setup({
  columns = {
    "icon",
    { "permissions", highlight = "Type" },
    { "size", highlight = "String" },
    { "mtime", highlight = "Keyword" },
  },
  keymaps = {
    ["h"] = { "actions.parent", mode = "n" }, -- "-" also navigates to parent
    ["q"] = { "actions.close", mode = "n" },
    ["gd"] = {
      desc = "Toggle file detail view",
      callback = function()
        detail = not detail
        if detail then
          require("oil").set_columns({
            "icon",
            { "permissions", highlight = "Type" },
            { "size", highlight = "String" },
            { "mtime", highlight = "Keyword" },
          })
        else
          require("oil").set_columns({ "icon" })
        end
      end,
    },
  },
  view_options = {
    show_hidden = false,
  },
  float = {
    border = "rounded",
    win_options = {
      winblend = 0,
    },
    max_width = 200,
    max_height = 0.8,
  },
  preview_win = {
    update_on_cursor_moved = true,
  },
  lsp_file_methods = {
    enabled = true,
    timeout_ms = 1000,
    autosave_changes = true,
  },
})

-- require("oil-git-status").setup()

-- Outline
require("outline").setup({})
vim.keymap.set("n", "<leader>oo", "<cmd>Outline<CR>", { desc = "Toggle outline" })

-- Git signs: hunk navigation/stage/reset/blame, ported from LazyVim's on_attach.
require("gitsigns").setup({
  on_attach = function(buffer)
    local gs = require("gitsigns")

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buffer, desc = desc, silent = true })
    end

    map("n", "]h", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gs.nav_hunk("next")
      end
    end, "Next Hunk")
    map("n", "[h", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gs.nav_hunk("prev")
      end
    end, "Prev Hunk")
    map("n", "]H", function()
      gs.nav_hunk("last")
    end, "Last Hunk")
    map("n", "[H", function()
      gs.nav_hunk("first")
    end, "First Hunk")

    map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
    map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
    map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
    map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
    map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
    map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
    map("n", "<leader>ghb", function()
      gs.blame_line({ full = true })
    end, "Blame Line")
    map("n", "<leader>ghB", function()
      gs.blame()
    end, "Blame Buffer")
    map("n", "<leader>ghd", gs.diffthis, "Diff This")
    map("n", "<leader>ghD", function()
      gs.diffthis("~")
    end, "Diff This ~")
    map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
  end,
})

-- Code Diff
require("codediff").setup({
  explorer = {
    width = 30,
    auto_open_on_cursor = true,
    view_mode = "tree", -- "list" or "tree"
    line_stats = {
      enabled = true,
    },
  },
  diff = {
    compact = true,
    compact_context_lines = 8,
    compact_sync_folds = true, -- open/close folds in both panes together
  },
  keymaps = {
    view = {},
  },
})
