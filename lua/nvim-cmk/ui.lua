---@type cmk.config
local config = require 'nvim-cmk.config'

local used = false
local buf = vim.api.nvim_create_buf(false, true)
local win = 0
local height = 0

local ns = vim.api.nvim_create_namespace("MyHighlight")
vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

local M = {}

function M.is_busy()
  return used
end

function M.get()
  used = true

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

  config.win_config["title"] = config.build_type

  if win ~= 0 and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_config(win, config.win_config)
  else
    win = vim.api.nvim_open_win(buf, false, config.win_config)
  end

  height = 0
  vim.api.nvim_set_current_win(win)
end

---@param stderr string?
---@param stdout string?
function M.insert(stderr, stdout)
  local err_lines = {}
  local lines = {}

  if stderr then
    for line in stderr:gmatch("[^\r\n]+") do
      table.insert(err_lines, line)
    end
  end

  if stdout then
    for line in stdout:gmatch("[^\r\n]+") do
      table.insert(lines, line)
    end
  end

  vim.schedule(
    function()
      vim.api.nvim_buf_set_lines(
        buf,
        height == 0 and -2 or -1,
        -1,
        false,
        err_lines
      )

      vim.api.nvim_buf_set_extmark(buf, ns, height, 0, {
        end_row = height + #err_lines,
        hl_group = "ErrorMsg", -- built-in red
      })

      height = height + #err_lines

      vim.api.nvim_buf_set_lines(
        buf,
        height == 0 and -2 or -1,
        -1,
        false,
        lines
      )

      height = height + #lines

      if win ~= 0 and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_height(win, math.min(height, config.win_max_height))

        if vim.api.nvim_win_get_cursor(win)[1] == height - #lines then
          vim.api.nvim_win_set_cursor(win, { height, 1 })
        end
      end
    end)
end

function M.release()
  used = false
end

function M.close()
  vim.schedule(function()
    vim.api.nvim_win_close(win, false)
  end)

  win = 0
end

function M.show()
  if not vim.api.nvim_win_is_valid(win) then win = 0 end
  if win == 0 then
    local win_config = config.win_config
    win_config["height"] = math.min(height, config.win_max_height)
    win_config["title"] = config.build_type

    win = vim.api.nvim_open_win(buf, false, win_config)
    vim.api.nvim_set_current_win(win)
  end
end

function M.toggle()
  if not vim.api.nvim_win_is_valid(win) then win = 0 end

  if win == 0 then
    local win_config = config.win_config
    win_config["height"] = math.min(height, config.win_max_height)
    win_config["title"] = config.build_type

    win = vim.api.nvim_open_win(buf, false, win_config)
    vim.api.nvim_set_current_win(win)
  else
    vim.api.nvim_win_close(win, false)
    win = 0
  end
end

return M
