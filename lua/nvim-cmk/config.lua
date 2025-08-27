---@module 'dap'
---@class cmk.config
---@field cwd string                            # Project root directory
---@field build_dir string                      # Name of the build directory (e.g. "bin/")
---@field build_type string                     # Currently selected build type (e.g. "Debug")
---@field BUILD_TYPES string[]                  # List of valid build types
---@field dap dap.Configuration                 # Debug Adapter Protocol config (from nvim-dap)
---@field root_marker string[]                  # Files or dirs used to detect project root
---@field register_autocmd boolean              # Whether to register autocmds automatically
---@field win_config vim.api.keyset.win_config  # Floating window configuration for UI
---@field win_max_height integer                # Maximum window height for UI
---@field auto_generate boolean                 # Whether to generate project files automatically

---@class cmk.opts
---@field root_marker? string[]                 # Override project root markers
---@field register_autocmd? boolean             # Override autocmd registration
---@field build_dir? string                     # Override build directory
---@field build_type? string                    # Override build type
---@field win_config? vim.api.keyset.win_config # Override floating window config
---@field win_max_height? integer               # Override maximum window height

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

local default_dap_config = {
  name = "nvim-cmk",
  type = "codelldb",
  request = "launch",
  program = "",
  cwd = "",
  stopAtEntry = false
}

---@type cmk.config
local default_config = {
  root_marker = { ".git", ".clang-format" },
  register_autocmd = true,
  auto_generate = true,
  build_dir = "bin/",
  build_type = "Debug",
  win_config = default_window_config,
  win_max_height = 15,
  cwd = "",
  dap = default_dap_config,
  BUILD_TYPES = { "Debug", "Release", "RelWithDebInfo", "MinSizeRel", },
}

local M = {}

---@param opts cmk.opts
M.setup = function(opts)
  ---@type cmk.config
  local new_conf = vim.tbl_deep_extend("keep", opts, default_config)

  local root = vim.fs.root(0, new_conf.root_marker)
  if not root then
    new_conf.cwd = vim.fn.input("Path to cwd: ", vim.fn.getcwd())
  else
    new_conf.cwd = root
  end

  new_conf.dap.cwd = new_conf.cwd
  new_conf.dap.program = new_conf.cwd .. "/" .. new_conf.build_dir .. "/" .. new_conf.build_type .. "/test/unit_tests"

  for k, v in pairs(new_conf) do
    M[k] = v
  end
end

return M
