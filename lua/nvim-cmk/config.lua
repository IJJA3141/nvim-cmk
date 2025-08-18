---@class cmk.config
---@field root_marker string[]
---@field register_autocmd  boolean
---@field build_dir string
---@field build_type cmk.build_type
---@field win_config vim.api.keyset.win_config
---@field win_max_height integer
---@field cwd string


---@class cmk.opts
---@field root_marker string[]?
---@field register_autocmd  boolean?
---@field build_dir string?
---@field build_type cmk.build_type?
---@field win_config vim.api.keyset.win_config?
---@field win_max_height integer?


---@type vim.api.keyset.win_config
local default_window_config = {
  relative = 'editor',
  row = 0,
  col = -1,
  height = 1,
  width = 80,
  anchor = 'NE',
  style = 'minimal',
  focusable = true,
  border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│", },
}


---@type cmk.config
local default_config = {
  root_marker = { ".git", ".clang-format" },
  register_autocmd = true,
  build_dir = "bin/",
  build_type = "Debug",
  win_config = default_window_config,
  win_max_height = 15,
  cwd = "",
}

local M = {}

---@param opts cmk.opts
M.setup = function(opts)
  ---@type cmk.config
  local new_conf = vim.tbl_deep_extend("keep", opts, default_config)

  local root = vim.fs.root(0, new_conf.root_marker)
  if not root then
    error("couldn't find root directory")
    return
  end

  new_conf.cwd = root

  for k, v in pairs(new_conf) do
    M[k] = v
  end
end

return M
