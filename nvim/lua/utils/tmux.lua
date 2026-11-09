-- Tmux mouse / history-limit management.
local M = {}

---@param enabled boolean
---@return boolean
function M.set(enabled)
  -- Only proceed if we're running inside a tmux session
  if not vim.env.TMUX then
    return false
  end

  local mouse_option = enabled and "on" or "off"
  local history_limit = enabled and "10000" or "1"

  -- Execute tmux commands and check for errors
  vim.fn.system("tmux set-option -g mouse " .. mouse_option)
  local mouse_error = vim.v.shell_error

  vim.fn.system("tmux set-option -g history-limit " .. history_limit)
  local history_error = vim.v.shell_error

  -- Report any errors to the user
  if mouse_error ~= 0 or history_error ~= 0 then
    vim.notify("Failed to configure tmux options", vim.log.levels.WARN)
    return false
  end

  vim.g.tmux_mouse_enabled = enabled
  return true
end

function M.disable()
  return M.set(false)
end

function M.enable()
  return M.set(true)
end

---@return boolean
function M.enabled()
  return vim.g.tmux_mouse_enabled == true
end

return M
