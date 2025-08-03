local M = {}

---@module 'nvim-cmk.config"
---@type cmk.config
local config = require 'nvim-cmk.config'.config

---@type integer
local buf = -1

---@type integer
local win = -1

---@type integer
local height = 0

---@return boolean
function M.create()
  if buf == -1 then
    buf = vim.api.nvim_create_buf(false, true)
    win = vim.api.nvim_open_win(buf, false, config.win_config)
    height = 0

    return false
  end

  return true
end

---@param result vim.SystemCompleted
function M.delete(result)
  if result.code == 0 then
    vim.schedule(function()
      vim.api.nvim_buf_delete(buf, {})
      buf = -1
    end)
  else
    M.insert(nil, result.stderr)
  end
end

---@param err string?
---@param stdout string?
function M.insert(err, stdout)
  if err then print(err) end

  -- add lines
  local lines = {}

  if stdout then
    for line in stdout:gmatch("[^\r\n]+") do
      table.insert(lines, line)
    end
  else
    table.insert(lines, "")
  end

  vim.schedule(function()
    vim.api.nvim_buf_set_lines(
      buf,
      height == 0 and -2 or -1,
      -1,
      false,
      lines
    )

    height = height + #lines

    if vim.api.nvim_win_is_valid(win) then
      -- resize window
      vim.api.nvim_win_set_height(win, math.min(height, config.win_max_height))

      -- scroll down
      if vim.api.nvim_win_get_cursor(win)[1] == height - #lines then
        vim.api.nvim_win_set_cursor(win, { height, 1 })
      end
    end
  end)
end

function M.show()
  if not vim.api.nvim_buf_is_valid(buf) then
    win = vim.api.nvim_open_win(buf, false, config.win_config)
  end
end

function M.hide()
  if not vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, false)
    win = -1
  end
end

return M
