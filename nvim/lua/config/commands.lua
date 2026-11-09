-- User commands.

vim.api.nvim_create_user_command("ToggleFormatter", function()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.b[bufnr].disable_autoformat = not vim.b[bufnr].disable_autoformat
  if vim.b[bufnr].disable_autoformat then
    vim.notify("Formatter disabled for this buffer", vim.log.levels.WARN)
  else
    vim.notify("Formatter enabled for this buffer", vim.log.levels.INFO)
  end
end, { desc = "Toggle formatter for current buffer" })
