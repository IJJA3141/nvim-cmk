local cmk = {}

---@param opts cmk.opts?
function cmk.setup(opts)
  local config = require 'nvim-cmk.config'
  config.setup(opts or {})

  local ui = require 'nvim-cmk.ui'
  local functions = require 'nvim-cmk.functions'

  cmk.show = ui.show
  cmk.hide = ui.hide
  cmk.toggle = ui.toggle

  cmk.set_build_type = functions.set_build_type
  cmk.generate = functions.generate
  cmk.build = functions.build
  cmk.test_all = functions.test_all
  cmk.test = functions.test
  cmk.dap = functions.dap

  cmk.cat = functions.cat
  cmk.clean = functions.clean

  local completion = function(_, _, _) return config.BUILD_TYPES end

  if config.register_autocmd then
    vim.api.nvim_create_user_command("CMakeShow", cmk.show, { desc = "Show CMake output" })
    vim.api.nvim_create_user_command("CMakeHide", cmk.hide, { desc = "Hide CMake output" })
    vim.api.nvim_create_user_command("CMakeToggle", cmk.toggle, { desc = "Toggle CMake output" })

    vim.api.nvim_create_user_command("CMakeSetBuildType", cmk.set_build_type, {
      desc = "Set current CMake build type",
      nargs = 1,
      complete = completion
    })

    vim.api.nvim_create_user_command("CMakeGenerate", cmk.generate, {
      desc = "Generate build files for current configuration",
      nargs = "?",
      complete = completion
    })

    vim.api.nvim_create_user_command("CMakeBuild", cmk.build, {
      desc = "Build project using current configuration",
      nargs = "?",
      complete = completion
    })

    vim.api.nvim_create_user_command("CMakeTestAll", cmk.test_all, {
      desc = "Run all tests in the project",
      nargs = "?",
      complete = completion
    })

    vim.api.nvim_create_user_command("CMakeTest", cmk.test, {
      desc = "Run the test in current file",
      nargs = "?",
      complete = completion
    })

    vim.api.nvim_create_user_command("CMakeDap", cmk.dap, {
      desc = "Launch test of current file in debugger for current configuration",
      nargs = "?",
      complete = completion
    })

    vim.api.nvim_create_user_command("CMakeCat", cmk.cat, {
      desc = "Display the most recent test log" })

    vim.api.nvim_create_user_command("CMakeClean", cmk.clean, {
      desc = "Remove build artifacts and tmp files" })
  end

  if config.auto_generate then
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "**/CMakeLists.txt",
      callback = function() cmk.generate() end,
    })
  end
end

return cmk
