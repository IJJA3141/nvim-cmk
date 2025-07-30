local M = {}

local ui = require('nvim-cmk.ui')

---@param opts cmk.Opts
---@retrun fun()
function M.generate(opts)
  return function()
    local popup = ui.create_popup(opts.window_max_height, opts.window_config)

    vim.system(
      { "cmake", "-S", "./", opts.build_dir },
      {
        cwd = opts.cwd,
        stdout = function(err, data)
          if err then print(err) end
          vim.schedule(function()
            popup.insert(data)
          end)
        end,
      },
      function(result)
        vim.schedule(function()
          if result.code == 0 then
            popup.close()
          end
        end)
      end
    )
  end
end

---@param opts cmk.Opts
---@return function(type:cmk.BuildType)
function M.build(opts)
  return function(type)
    local popup = ui.create_popup(opts.window_max_height, opts.window_config)

    print(vim.inspect(vim.system(
      { "cmake", "--build", opts.build_dir, "--config", type or opts.build_type },
      {
        cwd = opts.cwd,
        stdout = function(err, data)
          if err then print(err) end
          vim.schedule(function()
            popup.insert(data)
          end)
        end
      },
      function(result)
        vim.schedule(function()
          if result.code == 0 then
            popup.close()
          end
        end)
      end
    ).cmd))
  end
end

---@param opts cmk.Opts
---@return fun()
function M.build_test(opts)
  return function()
    local popup = ui.create_popup(opts.window_max_height, opts.window_config)

    vim.system(
      { "make" },
      {
        cwd = opts.cwd .. "/" .. opts.build_dir .. "/test/",
        stdout = function(err, data)
          if err then print(err) end
          vim.schedule(function()
            popup.insert(data)
          end)
        end
      },
      function(result)
        vim.schedule(function()
          if result.code == 0 then
            popup.close()
          end
        end)
      end
    )
  end
end

---@param opts cmk.Opts
---@return fun()
function M.run_test(opts)
  return function()
    local popup = ui.create_popup(opts.window_max_height, opts.window_config)

    vim.system(
      { "ctest", "--test-dir", "../" .. opts.build_dir },
      {
        cwd = opts.cwd .. "/test/",
        stdout = function(err, data)
          if err then print(err) end
          vim.schedule(function()
            popup.insert(data)
          end)
        end
      },
      function(result)
        vim.schedule(function()
          if result.code == 0 then
            popup.close()
          end
        end)
      end
    )
  end
end

---@param opts cmk.Opts
---@return fun()
function M.cat(opts)
  return function()
    local popup = ui.create_popup(opts.window_max_height, opts.window_config)

    vim.system(
      { "cat", "LastTest.log" },
      {
        cwd = opts.cwd .. "/" .. opts.build_dir .. "/Testing/Temporary/",
        stdout = function(err, data)
          if err then print(err) end
          vim.schedule(function()
            popup.insert(data)
          end)
        end
      },
      function(result)
        vim.schedule(function()
          if result.code == 0 then
            popup.close()
          end
        end)
      end
    )
  end
end

---@param opts cmk.Opts
---@return fun()
function M.clean(opts)
  return function()
    local popup = ui.create_popup(opts.window_max_height, opts.window_config)

    vim.system(
      { "rm", "-r", opts.build_dir, "compile_commands.json" },
      {
        cwd = opts.cwd,
        stdout = function(err, data)
          if err then print(err) end
          vim.schedule(function()
            popup.insert(data)
          end)
        end
      },
      function(result)
        vim.schedule(function()
          if result.code ~= 0 then
            print(result.stderr)
          end

          popup.close()
        end)
      end
    )
  end
end

return M
