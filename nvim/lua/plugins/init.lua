-- Plugin installation and load order (native vim.pack).
--
-- Every plugin is installed eagerly. Feature modules below run their own setup()
-- after the pack has been added, so dependencies are already on the runtimepath.

local function gh(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  --------------------------------------------------------------------------------
  -- Colorschemes
  --------------------------------------------------------------------------------
  { src = gh("catppuccin/nvim") },
  { src = gh("ofirgall/ofirkai.nvim") },
  { src = gh("craftzdog/solarized-osaka.nvim") },
  { src = gh("bluz71/vim-moonfly-colors") },
  { src = gh("marko-cerovac/material.nvim") },
  { src = gh("EdenEast/nightfox.nvim") },
  { src = gh("ayu-theme/ayu-vim") },
  { src = gh("bluz71/vim-nightfly-colors") },
  { src = gh("folke/tokyonight.nvim") },
  { src = gh("rose-pine/neovim") },
  { src = gh("Mofiqul/dracula.nvim") },
  { src = gh("uloco/bluloco.nvim") },
  { src = gh("rktjmp/lush.nvim") },
  { src = gh("rebelot/kanagawa.nvim") },
  { src = gh("vague2k/vague.nvim") },
  { src = gh("tyrannicaltoucan/vim-deep-space") },
  { src = gh("webhooked/kanso.nvim") },
  { src = gh("olimorris/onedarkpro.nvim") },
  { src = gh("NLKNguyen/papercolor-theme") },
  { src = gh("sainnhe/sonokai") },
  { src = gh("kamwitsta/vinyl.nvim") },

  --------------------------------------------------------------------------------
  -- Core / UI
  --------------------------------------------------------------------------------
  { src = gh("nvim-lua/plenary.nvim") },
  { src = gh("nvim-mini/mini.icons") },
  { src = gh("folke/snacks.nvim") },
  { src = gh("rachartier/tiny-cmdline.nvim") },
  { src = gh("MunifTanjim/nui.nvim") },
  { src = gh("nvim-lualine/lualine.nvim") },
  { src = gh("folke/which-key.nvim") },
  { src = gh("folke/twilight.nvim") },
  { src = gh("eandrju/cellular-automaton.nvim") },
  { src = gh("nvim-mini/mini.animate") },

  --------------------------------------------------------------------------------
  -- Editor
  --------------------------------------------------------------------------------
  { src = gh("folke/flash.nvim") },
  { src = gh("yousefhadder/markdown-plus.nvim") },
  { src = gh("nvim-mini/mini.pairs") },
  { src = gh("nvim-mini/mini.ai") },
  { src = gh("folke/ts-comments.nvim") },
  { src = gh("folke/todo-comments.nvim") },
  { src = gh("MagicDuck/grug-far.nvim") },
  { src = gh("nvim-neo-tree/neo-tree.nvim") },
  { src = gh("abecodes/tabout.nvim") },
  { src = gh("L3MON4D3/LuaSnip") },
  { src = gh("hrsh7th/nvim-cmp") },
  { src = gh("nvim-mini/mini.surround") },
  { src = gh("nvim-mini/mini.bracketed") },
  { src = gh("stevearc/quicker.nvim") },
  { src = gh("christoomey/vim-tmux-navigator") },
  { src = gh("aimdevlee/herdr-nvim-nav") },
  { src = gh("Tim4c/tuios-nvim-navigator") },
  { src = gh("wassimk/rex-navigator.nvim") },
  { src = gh("danymat/neogen") },
  { src = gh("lewis6991/async.nvim") },
  { src = gh("ThePrimeagen/refactoring.nvim") },
  { src = gh("monaqa/dial.nvim") },
  { src = gh("rmagatti/auto-session") },
  { src = gh("folke/persistence.nvim") },
  { src = gh("MeanderingProgrammer/render-markdown.nvim") },
  { src = gh("iamcco/markdown-preview.nvim") },

  --------------------------------------------------------------------------------
  -- Git / files
  --------------------------------------------------------------------------------
  { src = gh("lewis6991/gitsigns.nvim") },
  { src = gh("nvim-mini/mini.diff") },
  { src = gh("esmuellert/codediff.nvim") },
  { src = gh("stevearc/oil.nvim") },
  { src = gh("refractalize/oil-git-status.nvim") },
  { src = gh("hedyhli/outline.nvim") },
  { src = gh("georgeharker/comment-tasks.nvim") },

  --------------------------------------------------------------------------------
  -- LSP / completion / formatting
  --------------------------------------------------------------------------------
  { src = gh("saghen/blink.cmp"), version = vim.version.range("^1") },
  { src = gh("rafamadriz/friendly-snippets") },
  { src = gh("mikavilpas/blink-ripgrep.nvim") },
  { src = gh("giuxtaposition/blink-cmp-copilot") },
  { src = gh("zbirenbaum/copilot.lua") },
  { src = gh("mason-org/mason.nvim") },
  { src = gh("WhoIsSethDaniel/mason-tool-installer.nvim") },
  { src = gh("mason-org/mason-lspconfig.nvim") },
  { src = gh("neovim/nvim-lspconfig") },
  { src = gh("rachartier/tiny-inline-diagnostic.nvim") },
  { src = gh("smjonas/inc-rename.nvim") },
  { src = gh("mfussenegger/nvim-lint") },
  { src = gh("folke/trouble.nvim") },
  { src = gh("stevearc/conform.nvim") },
  { src = gh("folke/lazydev.nvim") },
  { src = gh("mrcjkb/rustaceanvim") },
  { src = gh("Saecki/crates.nvim") },
  { src = gh("b0o/SchemaStore.nvim") },

  --------------------------------------------------------------------------------
  -- Treesitter
  --------------------------------------------------------------------------------
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  { src = gh("nvim-treesitter/nvim-treesitter-textobjects"), version = "main" },
  { src = gh("windwp/nvim-ts-autotag") },

  --------------------------------------------------------------------------------
  -- AI
  --------------------------------------------------------------------------------
  { src = gh("nickjvandyke/opencode.nvim") },
}, { confirm = false })

require("plugins.ui")
require("plugins.treesitter")
require("plugins.editor")
require("plugins.lsp")
require("plugins.framework")
require("plugins.util")
require("plugins.keymaps")
require("plugins.ai")
