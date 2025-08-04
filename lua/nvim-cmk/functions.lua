local config = require 'nvim-cmk.config'
local ui = require 'nvim-cmk.ui'


---@class cmk.callback
---@field param cmk.callback?
---@field funct fun(success_handler:cmk.callback?, error_handler:cmk.callback?)


local M = {}

---@param build_type cmk.build_type
function M.set_build_type(build_type) config.build_type = build_type end

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
        if success_handler then
          ui.state = "callback_pending"
          success_handler.funct(success_handler.param)
        else
          ui.delete()
        end
      else
        if error_handler then
          ui.state = "callback_pending"
          error_handler.funct(error_handler.param)
        else
          error(result.err)
        end
      end
    end
    )
  end
end

M.generate = M.call(
  { "cmake", "-S", "./", config.build_dir },
  { cwd = config.cwd }
)

M.link = M.call(
  { "ln", "-s", config.build_dir .. "compile_commands.json", "compile_commands.json" },
  { cwd = config.cwd }
)

M.cat = M.call(
  { "cat", "LastTest.log" },
  { cwd = config.cwd .. "/" .. config.build_dir .. "/Testing/Temporary/", stdout = ui.insert }
)

M.clean = M.call(
  { "rm", "-r", config.build_dir, "compile_commands.json" },
  { cwd = config.cwd, stdout = ui.insert }
)

M.run_test = M.call(
  { "ctest", "--test-dir", "../" .. config.build_dir },
  { cwd = config.cwd .. "/test/", stdout = ui.insert }
)

M.build = M.call(
  { "cmake", "--build", config.build_dir, "--config", config.build_type },
  { cwd = config.cwd, stdout = ui.insert }
)

M.build_test = M.call(
  { "cmake", "--build", config.build_dir, "--config", config.build_type },
  { cwd = config.cwd .. "/" .. config.build_dir .. "/test/", stdout = ui.insert }
)

return M
