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
  local config = require 'nvim-cmk.config'
  config.setup(opts or {})

  local ui = require 'nvim-cmk.ui'
  local functions = require 'nvim-cmk.functions'

  cmk.show = ui.show
  cmk.hide = ui.hide

  cmk.call = functions.call
  cmk.set_build_type = functions.set_build_type

  cmk.generate = functions.generate
  cmk.link = functions.link

  cmk.build = functions.build
  cmk.build_test = functions.build_test

  cmk.run_test = functions.run_test
  cmk.cat = functions.cat

  cmk.clean = functions.clean

  if config.register_autocmd then
    vim.api.nvim_create_user_command("CMakeShow", cmk.show, { desc = "Show nvim-cmk popup" })
    vim.api.nvim_create_user_command("CMakeHide", cmk.hide, { desc = "Hide nvim-cmk popup" })

    vim.api.nvim_create_user_command("CMakeSetBuildType", function(args) cmk.set_build_type(args[1]) end, { desc = "Set the CMake build type" })
    vim.api.nvim_create_user_command("CMakeGenerate", function() cmk.generate({ funct = cmk.link }) end, { desc = "Generate project" })

    vim.api.nvim_create_user_command("CMakeBuild", function(args)
      local build_type

      if args and args[1] == cmk.BUILD_TYPES.Debug or args[1] == cmk.BUILD_TYPES.MinSizeRel or args[1] == cmk.BUILD_TYPES.RelWithDebInfo or args[1] == cmk.BUILD_TYPES.Release then
        build_type = config.build_type
        config.build_type = args[1]
      end

      cmk.build(nil, { funct = cmk.generate, param = { funct = cmk.build } })

      if build_type then config.build_type = build_type end
    end, { desc = "" })

    vim.api.nvim_create_user_command("CMakeBuildTest", function(args)
      local build_type

      if args and args[1] == cmk.BUILD_TYPES.Debug or args[1] == cmk.BUILD_TYPES.MinSizeRel or args[1] == cmk.BUILD_TYPES.RelWithDebInfo or args[1] == cmk.BUILD_TYPES.Release then
        build_type = config.build_type
        config.build_type = args[1]
      end

      cmk.build_test(nil, { funct = cmk.generate, param = { funct = cmk.build_test } })

      if build_type then config.build_type = build_type end
    end, { desc = "" })

    vim.api.nvim_create_user_command("CMakeRunTest", cmk.run_test, { desc = "" })
    vim.api.nvim_create_user_command("CMakeCat", cmk.cat, { desc = "" })

    vim.api.nvim_create_user_command("CMakeClean", cmk.clean, { desc = "" })
  end
end

return cmk
