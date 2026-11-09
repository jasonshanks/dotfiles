---@class utils.editor
local M = {}

-- Root detection markers
local root_patterns = { ".git", "lua", "package.json", "Makefile", "Cargo.toml", "go.mod", "pyproject.toml" }

--- Get the current working directory
---@return string
local function get_cwd()
  return vim.uv.cwd() or vim.fn.getcwd()
end

--- Normalize a path (resolve symlinks, ensure consistent format)
---@param path string
---@return string
local function normalize(path)
  if path:sub(1, 1) == "~" then
    path = vim.fn.expand(path)
  end
  path = vim.uv.fs_realpath(path) or path
  return path:gsub("/$", "")
end

--- Find the project root directory
---@return string
local function get_root()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    path = get_cwd()
  end
  path = vim.fs.dirname(path)

  local root = vim.fs.find(root_patterns, { path = path, upward = true })[1]
  if root then
    return normalize(vim.fs.dirname(root))
  end

  return normalize(get_cwd())
end

--- Check if a file exists
---@param filepath string
---@return boolean
local function file_exists(filepath)
  local stat = vim.uv.fs_stat(filepath)
  return stat ~= nil and stat.type == "file"
end

--- Copy selected lines as a Markdown codeblock with filename and line number
function M.copy_as_codeblock()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    vim.notify("Buffer has no file name", vim.log.levels.WARN)
    return
  end

  local root = get_root()
  local relative = filepath:sub(#root + 2)
  local ft_to_lang = {
    typescriptreact = "tsx",
    javascriptreact = "jsx",
    typescript = "ts",
    javascript = "js",
  }
  local lang = ft_to_lang[vim.bo.filetype] or vim.bo.filetype

  local result = {}
  table.insert(result, "```" .. lang .. ' filename="' .. relative .. '" line=' .. start_line)
  for _, line in ipairs(lines) do
    table.insert(result, line)
  end
  table.insert(result, "```")

  local text = table.concat(result, "\n")
  vim.fn.setreg("+", text)
  vim.notify("Copied " .. #lines .. " lines as codeblock", vim.log.levels.INFO)
end

function M.yank_relative_path_with_line()
  local path = vim.fn.expand("%:.") .. "#L" .. vim.fn.line(".")
  vim.fn.setreg("+", path)
  vim.notify("Yanked: " .. path, vim.log.levels.INFO)
end

function M.yank_absolute_path_with_line()
  local path = vim.fn.expand("%:p") .. "#L" .. vim.fn.line(".")
  vim.fn.setreg("+", path)
  vim.notify("Yanked: " .. path, vim.log.levels.INFO)
end

return M
