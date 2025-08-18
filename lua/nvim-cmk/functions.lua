local config = require 'nvim-cmk.config'
local ui = require 'nvim-cmk.ui'


---@class cmk.callback
---@field param_sucess cmk.callback?
---@field param_fail cmk.callback?
---@field funct fun(success_handler:cmk.callback?, error_handler:cmk.callback?)


local M = {}

---@param build_type cmk.build_type
function M.set_build_type(build_type)
  if build_type then
    if
        build_type[1] == "Debug" or
        build_type[1] == "Release" or
        build_type[1] == "RelWithDebInfo" or
        build_type[1] == "MinSizeRel"
    then
      config.build_type = build_type
    else
      error(build_type .. "isn't a build type see cmk.build_type")
    end
  end
end

---@param cmd any
---@param opts any
---@return fun(success_handler:cmk.callback?, error_handler:cmk.callback?)
function M.call(cmd, opts)
  opts.stdout = ui.insert

  return function(success_handler, error_handler)
    if ui.create() then
      error("cmake job already running !")
      return
    end

    vim.system(cmd, opts, function(result)
      if result.code == 0 then
        if success_handler and success_handler.funct then
          ui.state = "callback_pending"
          success_handler.funct(success_handler.param_sucess, success_handler.param_fail)
        else
          ui.state = "stopped"
          ui.delete()
        end
      else
        if error_handler and error_handler.funct then
          ui.state = "callback_pending"
          error_handler.funct(error_handler.param_sucess, error_handler.param_fail)
        else
          ui.state = "stopped"
          ui.insert(result.stderr)
        end
      end
    end)
  end
end

M.cat = function(success_handler, error_handler)
  if ui.create() then
    error("cmake job already running !")
    return
  end

  vim.system(
    { "cat", config.build_dir .. "/" .. config.build_type .. "/Testing/Temporary/LastTest.log" },
    { cwd = config.cwd, stdout = ui.insert },
    function(result)
      if result.code == 0 then
        ui.insert("", result.stdout)

        if success_handler and success_handler.funct then
          ui.state = "callback_pending"
          success_handler.funct(success_handler.param_sucess, success_handler.param_fail)
        else
          ui.state = "stopped"
        end
      else
        error(result.stderr)

        if error_handler and error_handler.funct then
          ui.state = "callback_pending"
          error_handler.funct(error_handler.param_sucess, error_handler.param_fail)
        else
          ui.state = "stopped"
          ui.delete()
        end
      end
    end
  )
end

M.generate = M.call(
  { "cmake", "-DCMAKE_BUILD_TYPE=" .. config.build_type,
    "-S", "./",
    "-B", config.build_dir .. "/" .. config.build_type },
  { cwd = config.cwd }
)

M.link = M.call(
  { "ln", "-fs", config.build_dir .. config.build_type .. "/compile_commands.json", "compile_commands.json" },
  { cwd = config.cwd }
)

M.clean = M.call(
  { "rm", "-rf", config.build_dir, "compile_commands.json" },
  { cwd = config.cwd, stdout = ui.insert }
)

M.run_test = M.call(
  { "ctest", "--test-dir", config.build_dir .. "/" .. config.build_type, "-VV", "--output-on-failure" },
  { cwd = config.cwd, stdout = ui.insert }
)

M.build = M.call(
  { "cmake", "--build", config.build_dir .. "/" .. config.build_type },
  { cwd = config.cwd, stdout = ui.insert }
)

M.build_test = M.call(
  { "cmake", "--build", config.build_dir .. "/" .. config.build_type .. "/test" },
  { cwd = config.cwd, stdout = ui.insert }
)

return M
