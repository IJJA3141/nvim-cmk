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
    vim.api.nvim_create_user_command("CMakeSetBuildType",
      function(args) cmk.set_build_type(args[1]) end,
      { desc = "Set the CMake build type" })

    vim.api.nvim_create_user_command("CMakeGenerate",
      function(args)
        local build_type = config.build_type

        cmk.set_build_type(args[1])
        cmk.generate({ funct = cmk.link })

        config.build_type = build_type
      end,
      { desc = "Generate project" })

    vim.api.nvim_create_user_command("CMakeBuild",
      function(args)
        if args and args[1] ~= config.build_type then
          local build_type = config.build_type

          cmk.set_build_type(args[1])
          cmk.generate({ funct = cmk.link, param_sucess = { funct = cmk.build } })

          config.build_type = build_type
        else
          cmk.build(nil, {
            funct = cmk.build,
            param_sucess = {
              funct = cmk.link,
              param_sucess = {
                funct = cmk.build
              }
            }
          }
          )
        end
      end,
      { desc = "" })

    vim.api.nvim_create_user_command("CMakeBuildTest",
      function(args)
        if args and args[1] ~= config.build_type then
          local build_type = config.build_type

          cmk.set_build_type(args[1])
          cmk.generate({ funct = cmk.link, param_sucess = { funct = cmk.build_test } })

          config.build_type = build_type
        else
          cmk.build_test(nil, {
            funct = cmk.build,
            param_sucess = {
              funct = cmk.link,
              param_sucess = {
                funct = cmk.build
              }
            }
          }
          )
        end
      end,
      { desc = "" })

    vim.api.nvim_create_user_command("CMakeRunTest",
      function() cmk.run_test(nil, { funct = cmk.cat }) end,
      { desc = "" })

    vim.api.nvim_create_user_command("CMakeCat", cmk.cat, { desc = "" })
    vim.api.nvim_create_user_command("CMakeClean", cmk.clean, { desc = "" })
  end
end

return cmk
