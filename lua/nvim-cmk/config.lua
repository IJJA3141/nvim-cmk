---@class cmk.config
---
---@field root_marker string[]
---@field register_autocmd  boolean
---
---@field build_dir string
---@field build_type cmk.build_type
---
---@field win_config vim.api.keyset.win_config
---@field win_max_height integer
---
---@field cwd string



---@class cmk.opts
---
---@field root_marker string[]?
---@field register_autocmd  boolean?
---
---@field build_dir string?
---@field build_type cmk.build_type?
---
---@field win_config vim.api.keyset.win_config?
---@field win_max_height integer?



local M = {}

---@type vim.api.keyset.win_config
local DEFAULT_WIN = {
  relative = 'win',
  row = 0,
  col = 0,
  height = 1,
  width = 80,
  anchor = 'NW',
  style = 'minimal',
  focusable = true,
  border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│", }
}


---@type cmk.config
local DEFAULT = {
  root_marker = { ".git" },
  register_autocmd = true,

  build_dir = "bin/",
  build_type = "Debug",

  win_config = DEFAULT_WIN,
  win_max_height = 15,
}

---@type cmk.config
M.config = DEFAULT

---@param opts cmk.opts
function M.set(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(M.config), opts)

  local root = vim.fs.root(0, M.config.root_marker)
  if not root then
    error("couldn't find root directory")
    return
  end

  M.config.cwd = root
  print(vim.inspect(M.config))
end

return M
