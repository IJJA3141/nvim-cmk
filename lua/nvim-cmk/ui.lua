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
  if M.state == UI_STATE.Stopped then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

    if win ~= 0 and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_config(win, config.win_config)
    else
      win = vim.api.nvim_open_win(buf, false, config.win_config)
    end

    height = 0
  end

  M.state = UI_STATE.Running
  return false
end

function M.delete()
  vim.schedule(function()
    vim.api.nvim_win_close(win, false)
    win = 0
  end)
end

---@param stderr string?
---@param stdout string?
function M.insert(stderr, stdout)
  if win == 0 then return end

  -- add lines
  local lines = {}

  if stdout then
    for line in stdout:gmatch("[^\r\n]+") do
      table.insert(lines, line)
    end
  elseif not stderr then
    table.insert(lines, "")
  end

  if stderr then
    for line in stderr:gmatch("[^\r\n]+") do
      table.insert(lines, line)
    end
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

    if stderr then vim.api.nvim_set_current_win(win) end
  end)
end

function M.show()
  if buf ~= 0 and vim.api.nvim_buf_is_valid(buf) and win == 0 then
    ---@type vim.api.keyset.win_config
    local conf = config.win_config
    conf.height = height

    win = vim.api.nvim_open_win(buf, false, conf)
    vim.api.nvim_set_current_win(win)
  end
end

function M.hide()
  if win ~= 0 and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, false)
    win = 0
  end
end

return M
