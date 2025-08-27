local cmk = {}

---@param opts cmk.opts?
function cmk.setup(opts)
  local config = require 'nvim-cmk.config'
  config.setup(opts or {})

  local ui = require 'nvim-cmk.ui'
  local functions = require 'nvim-cmk.functions'

  -- ui
  cmk.show = ui.show
  cmk.hide = ui.hide
  cmk.toggle = ui.toggle

  -- config
  cmk.set_build_type = functions.set_build_type

  -- comp
  cmk.generate = functions.generate
  cmk.build = functions.build
  cmk.clean = functions.clean

  -- test
  cmk.test_all = functions.test_all
  cmk.test = functions.test
  cmk.cat = functions.cat

  -- debug
  cmk.debug_main = functions.debug_main
  cmk.debug_test = functions.debug_test

  local completion = function(_, _, _) return config.BUILD_TYPES end

  if config.register_autocmd then
    local autocmds = {
      { "CMakeShow",   cmk.show,   { desc = "Show CMake output" } },
      { "CMakeHid",    cmk.hide,   { desc = "Hide CMake output" } },
      { "CMakeToggle", cmk.toggle, { desc = "Toggle CMake output" } },
      { "CMakeCat",    cmk.cat,    { desc = "Display the most recent test log" } },
      { "CMakeClean",  cmk.clean,  { desc = "Remove build artifacts and tmp files" } },
    }

    for _, autocmd in pairs(autocmds) do
      vim.api.nvim_create_user_command(autocmd[1], autocmd[2], autocmd[3])
    end

    autocmds = {
      { "CMakeSetBuildType", cmk.set_build_type, { desc = "Set current CMake build type" } },

      { "CMakeGenerate",     cmk.generate,       { desc = "Generate build files for current configuration" } },
      { "CMakeBuild",        cmk.build,          { desc = "Build project using current configuration" } },

      { "CMakeTestAll",      cmk.test_all,       { desc = "Run all tests in the project" } },
      { "CMakeTest",         cmk.test,           { desc = "Run the test in current file" } },

      { "CMakeDebug",        cmk.debug_main,     { desc = "Start a dap session" } },
      { "CMakeDebugTest",    cmk.debug_test,     { desc = "Start a dap session for current test file" } },
    }

    for _, autocmd in pairs(autocmds) do
      autocmd[3]["nargs"] = "?"
      autocmd[3]["complete"] = completion

      vim.api.nvim_create_user_command(autocmd[1], autocmd[2], autocmd[3])
    end
  end

  if config.auto_generate then
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "**/CMakeLists.txt",
      callback = function() cmk.generate() end,
    })
  end
end

return cmk
