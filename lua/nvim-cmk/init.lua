local cmk = {}

---@enum cmk.BuildType
cmk.BUILD_TYPES = {
  Debug = "Debug",
  Release = "Release",
  RelWithDebInfo = "RelWithDebInfo",
  MinSizeRel = "MinSizeRel",
}

---@class (exact) cmk.Opts
---@filed root_marker sring[]
---@field build_type cmk.BuildType
---@field cwd string
---@field build_dir string
---@field user_commands boolean
---@field call_back fun(result: vim.SystemCompleted)

---@class cmk.SetupOpts
---@filed root_marker sring[]?
---@field build_type cmk.BuildType?
---@field build_dir string?
---@field user_commands boolean?
---@field call_back fun(result: vim.SystemCompleted)?

---@type cmk.Opts
cmk.opts = {
  build_type = "Debug",
  root_marker = { ".git", "CMakeLists.txt", "compile_commands.json" },
  build_dir = "bin/",
  user_commands = true,
  call_back = function(result)
    if result.code ~= 0 then
      print(result.stderr)
    else
      print(result.stdout)
    end
  end
}

---@param on_exit fun(out: vim.SystemCompleted)?
function cmk.generate(on_exit)
  on_exit = on_exit or cmk.opts.call_back

  vim.system(
    { "cmake", "-S", "./", cmk.opts.build_dir },
    { cwd = cmk.opts.cwd },
    function(result)
      if result.code then
        on_exit(result)
      else
        vim.system(
          { "ln", "-s", cmk.opts.build_dir .. "/compile_commands.json", "compile_commands.json" },
          { cwd = cmk.opts.cwd },
          on_exit
        )
      end
    end
  )
end

---@param type cmk.BuildType?
---@param on_exit fun(out: vim.SystemCompleted)?
function cmk.build(type, on_exit)
  type = type or cmk.opts.build_type
  on_exit = on_exit or cmk.opts.call_back

  print(cmk.opts.cwd)

  vim.system(
    { "cmake", "--build", "bin/", "--config", "Release" },
    { cwd = cmk.opts.cwd },
    on_exit
  )
end

---@param type cmk.BuildType?
---@param on_exit fun(out: vim.SystemCompleted)?
function cmk.build_test(type, on_exit)
  type = type or cmk.opts.build_type
  on_exit = on_exit or cmk.opts.call_back

  vim.system({ "make" }, { cwd = cmk.opts.cwd .. "/" .. cmk.opts.build_dir .. "/test/" }, on_exit)
end

---@param on_exit fun(out: vim.SystemCompleted)?
function cmk.run_test(on_exit)
  on_exit = on_exit or cmk.opts.call_back

  vim.system(
    { "ctest", "--test-dir", "../" .. cmk.opts.build_dir },
    { cwd = cmk.opts.cwd .. "/test/" },
    on_exit
  )
end

---@param on_exit fun(out: vim.SystemCompleted)?
function cmk.cat(on_exit)
  on_exit = on_exit or cmk.opts.call_back

  vim.system(
    { "cat", "LastTest.log" },
    { cwd = cmk.opts.cwd .. "/" .. cmk.opts.build_dir .. "/Testing/Temporary/" },
    on_exit
  )
end

---@param on_exit fun(out: vim.SystemCompleted)?
function cmk.clean(on_exit)
  return vim.system(
    { "rm", "-r", cmk.opts.build_dir, "compile_commands.json" },
    { cwd = cmk.opts.cwd },
    on_exit
  )
end

--- user commands
local function generate()
  vim.cmd("wa")
  cmk.generate()
end

---@param type cmk.BuildType?
local function build(type)
  vim.cmd("wa")

  if not vim.fn.isdirectory(cmk.opts.build_dir) then
    cmk.generate(function(result)
      cmk.opts.call_back(result)

      if not result.code then
        cmk.build(type)
      end
    end)
  else
    cmk.build(type)
  end
end

---@param type cmk.BuildType
local function build_test(type)
  vim.cmd("wa")

  if not vim.fn.isdirectory(cmk.opts.build_dir) then
    cmk.generate(function(result)
      cmk.opts.call_back(result)

      if not result.code then
        cmk.build_test(type)
      end
    end)
  else
    cmk.build_test(type)
  end
end

---@param type cmk.BuildType
local function run_test(type)
  vim.cmd("wa")

  if not vim.fn.isdirectory(cmk.opts.build_dir) then
    cmk.generate(function(result)
      cmk.opts.call_back(result)

      if not result.code then
        cmk.build(type, function(res)
          cmk.opts.call_back(res)

          if not res.code then
            cmk.run_test()
          end
        end)
      end
    end)
  else
    cmk.build(type, function(result)
      cmk.opts.call_back(cmk)

      if not result.code then
        cmk.run_test()
      end
    end)
  end
end

---@param opts cmk.SetupOpts?
function cmk.setup(opts)
  cmk.opts = vim.tbl_deep_extend("force", cmk.opts, opts)

  local root = vim.fs.root(0, cmk.opts.root_marker)

  if root then
    cmk.opts.cwd = root
  else
    error("couldn't find root directory")
    return
  end

  if cmk.opts.user_commands then
    vim.api.nvim_create_user_command("CMakeGenerate", generate, { desc = "Generate the build system" })
    vim.api.nvim_create_user_command("CMakeBuild", build, { desc = "Build the project" })
    vim.api.nvim_create_user_command("CMakeBuildTest", build_test, { desc = "Build the test project" })
    vim.api.nvim_create_user_command("CMakeRunTest", run_test, { desc = "Build and run tests using CTest" })
    vim.api.nvim_create_user_command("CMakeCat", cmk.cat, { desc = "Show contents of LastTest.log" })
    vim.api.nvim_create_user_command("CMakeClean", cmk.clean, { desc = "Clean root dir" })
  end
end

return cmk
