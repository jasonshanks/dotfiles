return {
  'rmagatti/auto-session',
  lazy = false,

  ---enables autocomplete for opts
  ---@module "auto-session"
  ---@type AutoSession.Config
  opts = {
    suppressed_dirs = { '~/', '~/Sites', '~/Downloads', '/' },
    pre_save_cmds = {
        function()
            -- Close all folds before saving
            vim.cmd('silent! %foldopen!')
        end
    },
    -- log_level = 'debug',
  }
}
