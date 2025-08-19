local config = require 'nvim-cmk.config'
local ui = require 'nvim-cmk.ui'


local function is_in(build_type)
  for _, type in ipairs(config.BUILD_TYPES) do if build_type == type then return end end
  error(build_type .. " wasn't in the list of valid build types see cmk.config.build_types for more")
end

local function generate(callback)
  vim.system(
    { "cmake",
      "-DCMAKE_BUILD_TYPE=" .. config.build_type,
      "-S", ".",
      "-B", config.build_dir .. "/" .. config.build_type },
    { cwd = config.cwd, stdout = ui.insert },
    function(result)
      if result.code == 0 then
        if callback then
          callback.fn(callback.param)
        else
          print("build files succesfully generated")
          ui.release()
          ui.close()
        end
      else
        ui.release()
        error("failed to generate build files")
      end
    end
  )
end

local function build(callback)
  vim.system(
    { "cmake", "--build", config.build_dir .. "/" .. config.build_type },
    { cwd = config.cwd, stdout = ui.insert },
    function(result)
      if result.code == 0 then
        if callback then
          callback.fn(callback.param)
        else
          print("build succesfully")
          ui.release()
          ui.close()
        end
      else
        ui.release()
        error("failed to build")
      end
    end
  )
end

local function test_all()
  vim.system(
    { "ctest", "--test-dir", config.build_dir .. "/" .. config.build_type, "--output-on-failure" },
    { cwd = config.cwd, stdout = ui.insert },
    function(result)
      ui.release()

      if result.code == 0 then
        print("all tests passed")
        ui.close()
      else
        error("a test failed")
      end
    end
  )
end

local function test()
  vim.system(
    { "ctest", "--test-dir", config.build_dir .. "/" .. config.build_type, "-VV", vim.fn.expand("%:t:r") },
    { cwd = config.cwd, stdout = ui.insert },
    function(result)
      ui.release()

      if result.code == 0 then
        print(vim.fn.expand("%:t:r") .. " tests passed")
        ui.close()
      else
        error(vim.fn.expand("%:t:r") .. " failed")
      end
    end
  )
end

local M = {}

function M.set_build_type(opts)
  if opts.args ~= "" then is_in(opts.args)
    print("settings build_type to " .. opts.args)
    config.build_type = opts.args
  end
end

function M.generate(opts)
  if opts.args ~= "" then is_in(opts.args) end
  if ui.is_busy() then error("a nvim-cmk prosses is already running") end

  if opts.args ~= "" then config.build_type = opts.args end
  vim.cmd("wa")

  ui.get()

  generate()
end

function M.build(opts)
  if opts.args ~= "" then is_in(opts.args) end
  if ui.is_busy() then error("a nvim-cmk prosses is already running") end

  if opts.args ~= "" then config.build_type = opts.args end

  ui.get()

  if vim.fn.isdirectory(config.cwd .. "/" .. config.build_dir .. "/" .. config.build_type) == 1 then
    vim.cmd("wa") -- save all buffers
    build()
  else
    generate({ fn = build })
  end
end

function M.clean()
  print("test" .. config.cwd)

  vim.system(
    { "rm", "-rf", config.build_dir, "compile_commands.json" },
    { cwd = config.cwd }
  )
end

function M.test_all(opts)
  if opts.args~="" then is_in(opts.args) end
  if ui.is_busy() then error("a nvim-cmk prosses is already running") end

  if opts.args ~= "" then config.build_type = opts.args end

  ui.get()

  if vim.fn.isdirectory(config.cwd .. "/" .. config.build_dir .. "/" .. config.build_type) then
    vim.cmd("wa") -- save all buffers
    build({ fn = test_all })
  else
    generate({ fn = build, param = { fn = test_all } })
  end
end

function M.test(opts)
  if opts.args~="" then is_in(opts.args) end
  if ui.is_busy() then error("a nvim-cmk prosses is already running") end

  if opts.args ~= "" then config.build_type = opts.args end


  ui.get()
  if vim.fn.isdirectory(config.cwd .. "/" .. config.build_dir .. "/" .. config.build_type) then
    vim.cmd("wa") -- save all buffers
    build({ fn = test })
  else
    generate({ fn = build, param = { fn = test } })
  end
end

function M.dap()
  if ui.is_busy() then error("a nvim-cmk prosses is already running") end

  local function dap()
    vim.schedule(function()
      local dap_config = config.dap
      local name = vim.fn.expand("%:t:r")

      dap_config.args = { name }

      require("dap").run(dap_config)
    end)
  end

  if vim.fn.isdirectory(config.cwd .. "/" .. config.build_dir .. "/" .. config.build_type) then
    vim.cmd("wa") -- save all buffers
    build({ fn = dap })
  else
    generate({ fn = build, param = { fn = dap } })
  end
end

return M
