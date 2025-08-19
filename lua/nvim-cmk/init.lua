local cmk = {}

---@param opts cmk.opts?
function cmk.setup(opts)
  local config = require 'nvim-cmk.config'
  config.setup(opts or {})

  local ui = require 'nvim-cmk.ui'
  local functions = require 'nvim-cmk.functions'

  cmk.show = ui.show
  cmk.hide = ui.close
  cmk.toggle = ui.toggle

  cmk.set_build_type = functions.set_build_type
  cmk.generate = functions.generate
  cmk.build = functions.build
  cmk.test_all = functions.test_all
  cmk.test = functions.test
  cmk.dap = functions.dap
  cmk.clean = functions.clean

  print(vim.inspect(config.BUILD_TYPES))

  if config.register_autocmd then
    vim.api.nvim_create_user_command("CMakeShow", cmk.show, { desc = "Show nvim-cmk popup" })
    vim.api.nvim_create_user_command("CMakeHide", cmk.hide, { desc = "Hide nvim-cmk popup" })
    vim.api.nvim_create_user_command("CMakeToggle", cmk.toggle, { desc = "Toggle nvim-cmk popup" })

    vim.api.nvim_create_user_command("CMakeSetBuildType", cmk.set_build_type , {
        desc = "Set build type",
        nargs = "?",
        complete = function(_, _, _) return config.BUILD_TYPES end,
      })

    vim.api.nvim_create_user_command("CMakeGenerate", cmk.generate,
      {
        desc = "generate",
        nargs = "?",
        complete = function(_, _, _) return config.BUILD_TYPES end,
      })

    vim.api.nvim_create_user_command("CMakeBuild", cmk.build,
    { desc = "Build" , nargs = "?", complete = function(_, _, _) return config.BUILD_TYPES end, })

    vim.api.nvim_create_user_command("CMakeTestAll", cmk.test_all, { desc = "Run all tests" 
, nargs = "?", complete = function(_, _, _) return config.BUILD_TYPES end,
  })

    vim.api.nvim_create_user_command("CMakeTest",
      function(args) if args.args then cmk.test(args.args) end end,
      { desc = "Run a test"
, nargs = "?", complete = function(_, _, _) return config.BUILD_TYPES end,
    })

    vim.api.nvim_create_user_command("CMakeDap", cmk.dap, { desc = "Dap" })
    vim.api.nvim_create_user_command("CMakeClean", cmk.clean, { desc = "Clean" })
  end
end

return cmk
