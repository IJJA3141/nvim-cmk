local cmk = {}

---@enum cmk.BuildType
cmk.BUILD_TYPES = {
  Debug = "Debug",
  Release = "Release",
  RelWithDebInfo = "RelWithDebInfo",
  MinSizeRel = "MinSizeRel",
}

---@class (exact) cmk.Opts
---@field build_type cmk.BuildType
---@field root_marker string[]
---@field build_dir string
---@field default_commands boolean
---@field window_config vim.api.keyset.win_config
---
---@field cwd string

---@class cmk.SetupOpts
---@filed root_marker sring[]?
---@field build_type cmk.BuildType?
---@field build_dir string?
---@field default_commands boolean?
---@field window_config vim.api.keyset.win_config

---@param opts cmk.SetupOpts?
function cmk.setup(opts)
  ---@type cmk.Opts
  local default_opts = {
    build_type = "Debug",
    root_marker = { ".git", "CMakeLists.txt", "compile_commands.json" },
    build_dir = "bin/",
    default_commands = true,
  }

  cmk.opts = vim.tbl_deep_extend("force", default_opts, opts)

  local root = vim.fs.root(0, cmk.opts.root_marker)

  if root then
    cmk.opts.cwd = root
  else
    error("couldn't find root directory")
    return
  end

  local fn = require("nvim-cmk.functions")
  cmk.generate = fn.generate(cmk.opts)
  cmk.build = fn.build(cmk.opts)
  cmk.build_test = fn.build_test(cmk.opts)
  cmk.run_test = fn.run_test(cmk.opts)
  cmk.cat = fn.cat(cmk.opts)
  cmk.clean = fn.clean(cmk.opts)

  if cmk.opts.default_commands then
    vim.api.nvim_create_user_command("CMakeGenerate", cmk.generate, { desc = "Generate the build system" })
    vim.api.nvim_create_user_command("CMakeBuild", cmk.build, { desc = "Build the project" })
    vim.api.nvim_create_user_command("CMakeBuildTest", cmk.build_test, { desc = "Build the test project" })
    vim.api.nvim_create_user_command("CMakeRunTest", cmk.run_test, { desc = "Build and run tests using CTest" })
    vim.api.nvim_create_user_command("CMakeCat", cmk.cat, { desc = "Show contents of LastTest.log" })
    vim.api.nvim_create_user_command("CMakeClean", cmk.clean, { desc = "Clean root dir" })
  end
end

return cmk
