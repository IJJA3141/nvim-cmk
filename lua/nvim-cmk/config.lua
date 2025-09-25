---@module 'dap'

---@class cmk.config
---@field register_autocmd boolean
---@field auto_generate boolean
---@field root_marker string[]
---@field baleia boolean
---@field BUILD_TYPES string[]
---@field build_type string
---@field build_dir string
---@field dap dap.Configuration
---@field win_config vim.api.keyset.win_config
---@field win_max_height integer
---
---@field cwd string
---@field insert fun(buffer:integer,
---                  start:integer,
---                  end_:integer,
---                  strict_indexing:boolean,
---                  replacement: string[])

---@class cmk.opts
---
---@field register_autocmd boolean|nil
---Whether the plugin should automatically register its autocommands.
---Defaults to `true`.
---@see cmk.autocmd
---
---@field auto_generate boolean|nil
---If `true`, the plugin will automatically run CMake to generate project
---files when needed.
---Defaults to `true`.
---
---@field root_marker string[]|nil
---List of filenames or directory names used to detect the project root.
---Defaults to `{ ".git", ".clang-format" }`.
---
---@field baleia boolean
---If `true`, uses the [baleia](https://github.com/m00qek/baleia.nvim) plugin
---to colorize terminal output.
---(Requires baleia to be installed and added to dependencies.)
---Defaults to `false`.
---
---@field BUILD_TYPES string[]|nil
---List of valid CMake build types (for example `"Debug"`, `"Release"`,
---`"RelWithDebInfo"`, etc.).
---Defaults to `{ "Debug", "Release", "RelWithDebInfo", "MinSizeRel" }`.
---
---@field build_type string|nil
---The currently selected build type from `BUILD_TYPES` (for example `"Debug"`).
---Defaults to `"Debug"`.
---
---@field build_dir string|nil
---The name of the build directory where build files are generated
---(for example `"build/"` or `"bin/"`).
---Defaults to `"bin/"`.
---
---@field dap dap.Configuration|nil
---Default Debug Adapter Protocol (DAP) configuration passed to `nvim-dap`.
---Defaults to:
---```lua
---{
---  name = "nvim-cmk",
---  type = "codelldb",
---  request = "launch",
---  program = "",
---  cwd = "",
---  stopAtEntry = false
---}
---```
---
---@field win_config vim.api.keyset.win_config|nil
---Floating window configuration used by the plugin’s UI.
---Defaults to:
---```lua
---{
---  relative = 'editor',
---  row = 0,
---  col = -1,
---  height = 1,
---  width = 80,
---  anchor = 'NE',
---  style = 'minimal',
---  focusable = true,
---  border = { "╭","─","╮","│","╯","─","╰","│" },
---}
---```
---
---@field win_max_height integer|nil
---Maximum height of the plugin’s floating window.
---Defaults to `15`.

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

---@type dap.Configuration
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

  if new_conf.baleia then
    local baleia = require('baleia').setup()
    new_conf.insert = baleia.buf_set_lines
  else
    new_conf.insert = vim.api.nvim_buf_set_lines
  end

  new_conf.dap.cwd = new_conf.cwd
  new_conf.dap.program = new_conf.cwd .. "/" .. new_conf.build_dir .. "/" .. new_conf.build_type .. "/test/unit_tests"

  for k, v in pairs(new_conf) do
    M[k] = v
  end
end

return M
