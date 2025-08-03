---@type cmk.config
local config = require 'nvim-cmk.config'.config
local ui = require 'nvim-cmk.ui'

---@class cmk.on_exit
---@field call_back_param cmk.on_exit?
---@field call_back fun(on_exit: cmk.on_exit?)

local M = {}

---@param on_exit cmk.on_exit?
function M.generate(on_exit)
  if ui.create() then
    error("cmake job already running !")
    return
  end

  print(config.build_dir)
  print(config.cwd)

  vim.system(
    { "cmake", "-S", "./", config.build_dir },
    { cwd = config.cwd, stdout = ui.insert },
    function(result)
      if result.code == 0 then
        vim.system(
          { "ln", "-s", config.build_dir .. "compile_commands.json", "compile_commands.json" },
          { cwd = config.cwd, stdout = ui.insert },
          function(rresult)
            ui.delete(result)

            if rresult.code == 0 and on_exit and on_exit.call_back then
              on_exit.call_back(on_exit.call_back_param)
            end
          end
        )
      end
    end
  )
end

---@param on_exit cmk.on_exit?
---@param build_type cmk.build_type?
function M.build(on_exit, build_type)
  if ui.create() then
    error("cmake job already running !")
    return
  end

  vim.system(
    { "cmake", "--build", config.build_dir, "--config", build_type or config.build_type },
    { cwd = config.cwd, stdout = ui.insert },
    function(result)
      ui.delete(result)

      if result.code == 0 and on_exit and on_exit.call_back then
        on_exit.call_back(on_exit.call_back_param)
      end
    end
  )
end

---@param on_exit cmk.on_exit?
---@param build_type cmk.build_type?
function M.build_test(on_exit, build_type)
  if ui.create() then
    error("cmake job already running !")
    return
  end

  vim.system(
    { "cmake", "--build", config.build_dir, "--config", build_type or config.build_type },
    { cwd = config.cwd .. "/" .. config.build_dir .. "/test/", stdout = ui.insert },
    function(result)
      ui.delete(result)

      if result.code == 0 and on_exit and on_exit.call_back then
        on_exit.call_back(on_exit.call_back_param)
      end
    end
  )
end

---@param on_exit cmk.on_exit?
function M.run_test(on_exit)
  if ui.create() then
    error("cmake job already running !")
    return
  end

  print(vim.inspect(config))

  vim.system(
    { "ctest", "--test-dir", "../" .. config.build_dir },
    { cwd = d .. "/test/", stdout = ui.insert },
    function(result)
      ui.delete(result)

      if result.code == 0 and on_exit and on_exit.call_back then
        on_exit.call_back(on_exit.call_back_param)
      end
    end
  )
end

---@param on_exit cmk.on_exit?
function M.cat(on_exit)
  if ui.create() then
    error("cmake job already running !")
    return
  end

  vim.system(
    { "cat", "LastTest.log" },
    { cwd = config.cwd .. "/" .. config.build_dir .. "/Testing/Temporary/", stdout = ui.insert },
    function(result)
      ui.delete(result)

      if result.code == 0 and on_exit and on_exit.call_back then
        on_exit.call_back(on_exit.call_back_param)
      end
    end
  )
end

---@param on_exit cmk.on_exit?
function M.clean(on_exit)
  if ui.create() then
    error("cmake job already running !")
    return
  end

  vim.system(
    { "rm", "-r", config.build_dir, "compile_commands.json" },
    { cwd = config.cwd, stdout = ui.insert },
    function(result)
      ui.delete(result)

      if result.code == 0 and on_exit and on_exit.call_back then
        on_exit.call_back(on_exit.call_back_param)
      end
    end
  )
end

return M
