return {
  "rmagatti/auto-session",
  lazy = false,
  opts = {
    suppressed_dirs = { "~/", "~/Sites", "~/Downloads", "/" },
    pre_save_cmds = {
      "silent! %foldopen!", -- Open all folds before saving
      function()
        -- Reset all folds before saving
        pcall(vim.cmd, "silent! normal! zE")
      end,
    },
    pre_restore_cmds = {
      "silent! %foldopen!", -- Open all folds before restoring
    },
    post_restore_cmds = {
      function()
        -- Reset fold settings after restore
        pcall(function()
          vim.cmd("silent! normal! zN") -- ensure folding is on
          vim.cmd("silent! normal! zx") -- recompute folds
        end)
      end,
    },
    save_extra_cmds = {
      "set foldmethod?", -- save the fold method
      "set foldenable?", -- save fold enable state
    },
    -- log_level = 'debug',
  },
}
