local cmk = {}

---@enum buildType
cmk.BUILD_TYPES = {
  Debug = "Debug",
  Release = "Release",
  RelWithDebInfo = "RelWithDebInfo",
  MinSizeRel = "MinSizeRel",
}

---@class (exact) cmk.Opts
---@filed root_marker sring[]
---@field build_type buildType
---@field cwd string
---@field build_dir string
---@field user_commands boolean
---@field call_back fun(result: vim.SystemCompleted)

---@class cmk.SetupOpts
---@filed root_marker sring[]?
---@field build_type buildType?
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

function cmk.generate()
  vim.system(
    {
      "cmake", "-S", "./", cmk.opts.build_dir, "&&",
      "ln", "-s", cmk.opts.build_dir .. "/compile_commands.json", "compile_commands.json"
    },
    { cwd = cmk.opts.cwd }, cmk.opts.call_back)
end

---@param type buildType?
function cmk.build(type)
  type = type or cmk.opts.build_type
  vim.system(
    { "cmake", ".", "--config", type },
    { cwd = cmk.opts.cwd .. "/" .. cmk.opts.build_dir },
    cmk.opts.call_back
  )
end

---@param type buildType?
function cmk.build_test(type)
  type = type or cmk.opts.build_type
  vim.system(
    { "cmake", ".", "--config", type },
    { cwd = cmk.opts.cwd .. "/" .. cmk.opts.build_dir .. "/test/" },
    cmk.call_back
  )
end

function cmk.run_test()
  cmk.cmakebuild()
  vim.system(
    { "ctest", "--test-dir", "../" .. cmk.opts.build_dir },
    { cwd = cmk.opts.cwd .. "/test/" },
    cmk.opts.call_back
  )
end

function cmk.cat()
  vim.system(
    { "cat", "LastTest.log" },
    { cwd = cmk.opts.cwd .. "/" .. cmk.opts.build_dir .. "/Testing/Temporary/" },
    cmk.opts.call_back
  )
end

function cmk.clean()
  vim.system(
    { "rm", "-r", cmk.opts.build_dir, "compile_commands.json" },
    { cwd = cmk.opts.cwd },
    cmk.opts.call_back
  )
end

--- user commands
local function generate()
  vim.cmd("wa")
  cmk.generate()
end

local function build()
  vim.cmd("wa")

  if not vim.fn.isdirectory(cmk.opts.build_dir) then
    cmk.generate()
  end

  cmk.build()
end

local function build_test()
  vim.cmd("wa")

  if not vim.fn.isdirectory(cmk.opts.build_dir) then
    cmk.generate()
  end

  cmk.build_test()
end

local function run_test()
  build()
  cmk.run_test()
end

---@param opts cmk.SetupOpts?
function cmk.setup(opts)
  cmk.opts = vim.tbl_deep_extend("force", cmk.opts, opts)

  print(cmk.opts.root_marker)
  local root = vim.fs.root(0, cmk.opts.root_marker)

  if root then cmk.opts.cwd = root
  else error("couldn't find root directory") return end

  if cmk.userCommands then
    vim.api.nvim_create_user_command("CMakeGenerate", generate, { desc = "Generate the build system" })
    vim.api.nvim_create_user_command("CMakeBuild", build, { desc = "Build the project" })
    vim.api.nvim_create_user_command("CMakeBuildTest", build_test, { desc = "Build the test project" })
    vim.api.nvim_create_user_command("CMakeRunTest", run_test, { desc = "Build and run tests using CTest" })
    vim.api.nvim_create_user_command("CMakeCat", cmk.cat, { desc = "Show contents of LastTest.log" })
    vim.api.nvim_create_user_command("CMakeClean", cmk.clean, { desc = "Clean root dir" })
  end
end

return cmk
