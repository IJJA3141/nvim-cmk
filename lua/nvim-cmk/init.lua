local config = require 'nvim-cmk.config'
local functions = require 'nvim-cmk.functions'
local ui = require 'nvim-cmk.ui'

local cmk = {}

---@enum cmk.build_type
cmk.BUILD_TYPES = {
  Debug = "Debug",
  Release = "Release",
  RelWithDebInfo = "RelWithDebInfo",
  MinSizeRel = "MinSizeRel",
}

---@param opts cmk.opts?
function cmk.setup(opts)
  if opts then config.set(opts) end

  cmk.generate = functions.generate
  cmk.build = functions.build
  cmk.build_test = functions.build_test
  cmk.run_test = functions.run_test
  cmk.cat = functions.cat
  cmk.clean = functions.clean
  cmk.show = ui.show
  cmk.hide = ui.hide

  if config.config.register_autocmd then
    vim.api.nvim_create_user_command("CMakeGenerate", cmk.generate, { desc = "Generate the build system" })
    vim.api.nvim_create_user_command("CMakeBuild", cmk.build, { desc = "Build the project" })
    vim.api.nvim_create_user_command("CMakeBuildTest", cmk.build_test, { desc = "Build the test project" })
    vim.api.nvim_create_user_command("CMakeRunTest", cmk.run_test, { desc = "Build and run tests using CTest" })
    vim.api.nvim_create_user_command("CMakeCat", cmk.cat, { desc = "Show contents of LastTest.log" })
    vim.api.nvim_create_user_command("CMakeClean", cmk.clean, { desc = "Clean root dir" })
    vim.api.nvim_create_user_command("CMakeShow", cmk.show, { desc = "Shows the popup window" })
    vim.api.nvim_create_user_command("CMakeHide", cmk.hide, { desc = "Hides the popup window" })
  end
end

return cmk
