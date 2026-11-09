-- 🌳 Treesitter: syntax-aware parsing for highlighting, navigation, and text objects.

local TS = require("nvim-treesitter")

local ensure_installed = {
  "bash",
  "c",
  "comment",
  "css",
  "diff",
  "fish",
  "git_config",
  "gitcommit",
  "gitignore",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "json5",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "php",
  "printf",
  "python",
  "regex",
  "rust",
  "scss",
  "ssh_config",
  "sql",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
}

-- util.dot extra: dotfile-oriented filetypes.
local xdg_config = vim.env.XDG_CONFIG_HOME or vim.env.HOME .. "/.config"
local function have(path)
  return vim.uv.fs_stat(xdg_config .. "/" .. path) ~= nil
end

vim.filetype.add({
  extension = { rasi = "rasi", rofi = "rasi", wofi = "rasi" },
  filename = {
    ["vifmrc"] = "vim",
  },
  pattern = {
    [".*/waybar/config"] = "jsonc",
    [".*/mako/config"] = "dosini",
    [".*/kitty/.+%.conf"] = "kitty",
    [".*/hypr/.+%.conf"] = "hyprlang",
    ["%.env%.[%w_.-]+"] = "sh",
  },
})
vim.treesitter.language.register("bash", "kitty")

if have("hypr") then
  table.insert(ensure_installed, "hyprlang")
end

if have("rofi") or have("wofi") then
  table.insert(ensure_installed, "rasi")
end

-- The main branch only accepts `install_dir` in setup(); indent/fold/selection
-- options live in the FileType autocmd below.
pcall(TS.setup, {})

-- Install missing parsers when the tree-sitter CLI is available. Deferred so a
-- first startup never blocks on compiling parsers.
if vim.fn.executable("tree-sitter") == 1 then
  vim.schedule(function()
    pcall(TS.install, ensure_installed)
  end)
end

-- Highlighting + treesitter indentation.
local treesitter_group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = treesitter_group,
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang then
      return
    end
    if not pcall(vim.treesitter.language.add, lang) then
      return
    end

    local started = pcall(vim.treesitter.start, ev.buf, lang)
    vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

    -- Tree-sitter folding (the old LazyVim config had `fold = { enable = true }`;
    -- on nvim-treesitter main this is done with the native API). foldlevel is
    -- left alone so the global 99 keeps folds open; LSP folding overrides this
    -- in lsp.lua when the server supports textDocument/foldingRange.
    if started then
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == ev.buf and vim.wo[win].foldmethod ~= "expr" then
          vim.wo[win].foldmethod = "expr"
          vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
        end
      end
    end
  end,
})

-- Re-run TSUpdate after vim.pack installs/updates nvim-treesitter.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
      vim.cmd("TSUpdate")
    end
  end,
})
