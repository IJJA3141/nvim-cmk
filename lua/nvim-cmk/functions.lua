---@type cmk.config
local config = require 'nvim-cmk.config'
local ui = require 'nvim-cmk.ui'
local name = nil

---@class cmk.callback
---
---@field args any
---Optional arguments passed to the current function.
---
---@field fn fun(cb:cmk.callback|nil)
---The next function to be executed once the current step completes.
---
---@field next cmk.callback|nil
---The callback data that will be passed to `fn` when it is invoked.

---@param callback cmk.callback|nil
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
          callback.fn(callback.next)
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

---@param callback cmk.callback|nil
local function build(callback)
  vim.system(
    { "cmake", "--build", config.build_dir .. "/" .. config.build_type },
    { cwd = config.cwd, stdout = ui.insert },
    function(result)
      if result.code == 0 then
        if callback then
          callback.fn(callback.next)
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

---@param callback cmk.callback|nil
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
          callback.fn(callback.next)
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

---@param callback cmk.callback|nil
local function test(callback)
  vim.schedule(function()
    vim.system(
      {
        "ctest", "-VV",
        "--test-dir", config.build_dir .. "/" .. config.build_type,
        "-R", vim.fn.expand("#:.:r"):sub(6)
      },
      { cwd = config.cwd, stdout = ui.insert },
      function(result)
        if result.code == 0 then
          if callback then
            callback.fn(callback.next)
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

local function debug_test()
  ui.hide() -- important for timing

  vim.schedule(function()
    local conf = {
      name = "test",
      type = "codelldb",
      request = "launch",
      program = function()
        return
            config.cwd .. "/" ..
            config.build_dir .. "/" ..
            config.build_type ..
            "/test/unit_tests"
      end,
      args = { vim.fn.expand("%:t:r") },
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
    }

    require("dap").run(conf, {})
  end)
end

local function debug_main()
  ui.hide() -- important for timing

  vim.schedule(function()
    if not name then
      name = vim.fn.fnamemodify(
        vim.fn.input(
          "Executable name: ",
          config.cwd .. "/" ..
          config.build_dir .. "/" ..
          config.build_type .. "/src/",
          "file"
        ), ":t"
      )
    end

    local conf = {
      name = "test",
      type = "codelldb",
      request = "launch",
      program = function()
        return
            config.cwd .. "/" ..
            config.build_dir .. "/" ..
            config.build_type .. "/src/" .. name
      end,
      args = { vim.fn.expand("%:t:r") },
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
    }

    require("dap").run(conf, {})
  end)
end

local M = {}

---@param opts vim.api.keyset.parse_cmd
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
  if vim.fn.isdirectory(config.cwd .. "/" .. config.build_dir .. "/" .. config.build_type) == 1 then
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
  if vim.fn.isdirectory(config.cwd .. "/" .. config.build_dir .. "/" .. config.build_type) == 1 then
    build({ fn = test })
  else
    generate({ fn = build, param = { fn = test } })
  end
end

function M.debug_test(opts)
  if require('dap').session() ~= nil then return end

  if ui.running then error("A nvim-cmk process is already running") end
  M.set_build_type(opts)
  vim.cmd("wa")

  ui.start()
  if vim.fn.isdirectory(config.cwd .. "/" .. config.build_dir .. "/" .. config.build_type) == 1 then
    build({ fn = debug_test })
  else
    generate({ fn = build, param = { fn = debug_test } })
  end
end

function M.debug_main(opts)
  if require('dap').session() ~= nil then return end

  if ui.running then error("A nvim-cmk process is already running") end
  M.set_build_type(opts)
  vim.cmd("wa")

  ui.start()
  if vim.fn.isdirectory(config.cwd .. "/" .. config.build_dir .. "/" .. config.build_type) == 1 then
    build({ fn = debug_main })
  else
    generate({ fn = build, param = { fn = debug_main } })
  end
end

return M
