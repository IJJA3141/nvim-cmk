local config = require 'nvim-cmk.config'
local ui = require 'nvim-cmk.ui'

---@class callback
---@field fn fun(callback:callback?)
---@field param callback

---@param callback callback?
local function generate(callback)
  vim.system(
    { "cmake",
      "-DCMAKE_BUILD_TYPE=" .. config.build_type,
      "-S", ".",
      "-B", config.build_dir .. "/" .. config.build_type
    },
    { cwd = config.cwd, stdout = ui.insert },
    function(result)
      if result.code == 0 then
        if callback then
          callback.fn(callback.param)
        else
          print("Build files generated successfully")
          ui.hide()
        end
      else
        ui.insert(result.stderr, result.stdout)
        ui.running = false
      end
    end
  )
end

---@param callback callback?
local function build(callback)
  vim.system(
    { "cmake", "--build", config.build_dir .. "/" .. config.build_type },
    { cwd = config.cwd, stdout = ui.insert },
    function(result)
      if result.code == 0 then
        if callback then
          callback.fn(callback.param)
        else
          print("Project built successfully")
          ui.hide()
        end
      else
        ui.insert(result.stderr, result.stdout)
        ui.running = false
      end
    end
  )
end

---@param callback callback?
local function test_all(callback)
  vim.system(
    {
      "ctest", "--output-on-failure",
      "--test-dir", config.build_dir .. "/" .. config.build_type,
    },
    { cwd = config.cwd, stdout = ui.insert },
    function(result)
      if result.code == 0 then
        if callback then
          callback.fn(callback.param)
        else
          print("All tests passed successfully")
          ui.hide()
        end
      else
        ui.insert(result.stderr, result.stdout)
        ui.running = false
      end
    end
  )
end

---@param callback callback?
local function test(callback)
  vim.schedule(function()
    vim.system(
      {
        "ctest", "-VV",
        "--test-dir", config.build_dir .. "/" .. config.build_type,
        vim.fn.expand("%:t:r")
      },
      { cwd = config.cwd, stdout = ui.insert },
      function(result)
        if result.code == 0 then
          if callback then
            callback.fn(callback.param)
          else
            print("succesfully builed")
            ui.hide()
          end
        else
          ui.insert(result.stderr, result.stdout)
          ui.running = false
        end
      end
    )
  end)
end

local function dap()
  vim.schedule(function()
    config.dap.args = { vim.fn.expand("%:t:r") }
    require("dap").run(config.dap)
  end)
end

local M = {}

function M.set_build_type(opts)
  if opts and opts.args ~= "" then
    for _, type in ipairs(config.BUILD_TYPES) do
      if opts.args == type then
        print("Build type set to " .. opts.args)
        config.build_type = opts.args

        return
      end
    end

    error(opts.args .. " wasn't in the list of valid build types see cmk.config.build_types for more")
  end
end

function M.generate(opts)
  if ui.running then error("A nvim-cmk process is already running") end
  M.set_build_type(opts)
  vim.cmd("wa")

  ui.start()
  generate()
end

function M.build(opts)
  if ui.running then error("A nvim-cmk process is already running") end
  M.set_build_type(opts)
  vim.cmd("wa")

  ui.start()
  if vim.fn.isdirectory(config.cwd .. "/" .. config.build_dir .. "/" .. config.build_type) == 1 then
    build()
  else
    generate({ fn = build })
  end
end

function M.clean()
  vim.system(
    { "rm", "-rf", config.build_dir, "compile_commands.json" },
    { cwd = config.cwd }
  )
end

function M.cat()
  if ui.running then error("A nvim-cmk process is already running") end
  ui.start()

  vim.system(
    { "cat", config.build_dir .. "/" .. config.build_type .. "/Testing/Temporary/LastTest.log" },
    { cwd = config.cwd, stdout = ui.insert },
    function(result)
      if result.code == 0 then
        ui.running = false
      else
        ui.insert(result.stderr, result.stdout)
        ui.running = false
      end
    end
  )
end

function M.test_all(opts)
  if ui.running then error("A nvim-cmk process is already running") end
  M.set_build_type(opts)
  vim.cmd("wa")

  ui.start()
  if vim.fn.isdirectory(config.cwd .. "/" .. config.build_dir .. "/" .. config.build_type) then
    build({ fn = test_all })
  else
    generate({ fn = build, param = { fn = test_all } })
  end
end

function M.test(opts)
  if ui.running then error("A nvim-cmk process is already running") end
  M.set_build_type(opts)
  vim.cmd("wa")

  ui.start()
  if vim.fn.isdirectory(config.cwd .. "/" .. config.build_dir .. "/" .. config.build_type) then
    build({ fn = test })
  else
    generate({ fn = build, param = { fn = test } })
  end
end

function M.dap(opts)
  if ui.running then error("A nvim-cmk process is already running") end
  M.set_build_type(opts)
  vim.cmd("wa")

  ui.start()
  if vim.fn.isdirectory(config.cwd .. "/" .. config.build_dir .. "/" .. config.build_type) then
    build({ fn = dap })
  else
    generate({ fn = build, param = { fn = dap } })
  end
end

return M
