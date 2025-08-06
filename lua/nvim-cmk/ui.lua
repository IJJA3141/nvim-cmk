---@type cmk.config
local config = require 'nvim-cmk.config'

---@enum cmk.ui_state
local UI_STATE = {
  Running = "running",
  Stopped = "stopped",
  Callback_pending = "callback_pending"
}

local buf = vim.api.nvim_create_buf(false, true)
local win = 0
local height = 0

local M = {}

---@type cmk.ui_state
M.state = UI_STATE.Stopped

---@return boolean
function M.create()
  if M.state == UI_STATE.Running then return true end
  if M.state == UI_STATE.Running then
    if win == 0 then
      win = vim.api.nvim_open_win(buf, false, config.win_config)
    else
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
      vim.api.nvim_win_set_config(win, config.win_config)
    end

    height = 0
  end

  M.state = UI_STATE.Running
  return false
end

function M.delete()
  vim.schedule(function() vim.api.nvim_win_close(win, false) end)
  -- win = 0
end

---@param stderr string?
---@param stdout string?
function M.insert(stderr, stdout)
  if stderr then print(stderr) end

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
  if buf ~= 0 and vim.api.nvim_buf_is_valid(buf) and win == 0 then
    win = vim.api.nvim_open_win(buf, false, config.win_config)
  end
end

function M.hide()
  if win ~= 0 and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, false)
    win = 0
  end
end

return M
