-- Native vim.pack based config (no lazy.nvim / LazyVim).
if vim.loader then
  vim.loader.enable()
end

-- Debug helper: `dd(value)` from anywhere.
_G.dd = function(...)
  require("utils.debug").dump(...)
end

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.commands")
require("config.workarounds")

require("plugins")
