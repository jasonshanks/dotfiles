-- 🤖 AI: AI completion and the OpenCode v2 server/TUI manager.

-- Copilot completions are provided through blink.cmp, not inline suggestions.
require("copilot").setup({
  suggestion = { enabled = false },
  panel = { enabled = false },
  filetypes = {
    markdown = true,
    help = true,
  },
})

-- OpenCode (https://github.com/nickjvandyke/opencode.nvim)
local opencode = require("utils.opencode")
opencode.setup()

local map = vim.keymap.set

map("n", "<leader>ot", function()
  opencode.toggle_tui()
end, { desc = "Toggle opencode TUI" })

map("n", "<leader>oa", function()
  opencode.ask_new_session("@cursor: ")
end, { desc = "Ask opencode" })

map("v", "<leader>oa", function()
  opencode.ask_new_session("@selection: ")
end, { desc = "Ask opencode about selection" })

map({ "n", "v" }, "<leader>op", function()
  if opencode.ensure_opencode() then
    require("opencode").select()
  end
end, { desc = "Select prompt" })

map("n", "<leader>on", function()
  if opencode.ensure_opencode() then
    require("opencode").command("session_new")
  end
end, { desc = "New session" })

map("n", "<leader>os", function()
  opencode.pick_session()
end, { desc = "Pick opencode session" })

map("n", "<leader>oy", function()
  if opencode.ensure_opencode() then
    require("opencode").command("messages_copy")
  end
end, { desc = "Copy last message" })

map("n", "<S-C-u>", function()
  if opencode.ensure_opencode() then
    require("opencode").command("messages_half_page_up")
  end
end, { desc = "Scroll messages up" })

map("n", "<S-C-d>", function()
  if opencode.ensure_opencode() then
    require("opencode").command("messages_half_page_down")
  end
end, { desc = "Scroll messages down" })
