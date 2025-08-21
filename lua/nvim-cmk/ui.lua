---@type cmk.config
local config = require 'nvim-cmk.config'

local buf = vim.api.nvim_create_buf(false, true)
local win = 0
local height = 1

local ns = vim.api.nvim_create_namespace("MyHighlight")
vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

local M = {}

M.running = false

function M.show()
  if win == 0 or not vim.api.nvim_win_is_valid(win) then
    config.win_config.height = math.min(height, config.win_max_height)
    config.win_config.title = config.build_type

    win = vim.api.nvim_open_win(buf, false, config.win_config)
    vim.api.nvim_set_current_win(win)

    vim.api.nvim_create_autocmd("WinLeave", {
      callback = M.hide, buffer = buf }) -- auto close win on leave
  end
end

function M.hide()
  vim.schedule(function()
    if win ~= 0 and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true) -- close window
      win = 0                           -- reset window
      M.running = false                 -- release
    end
  end)
end

function M.toggle() if win == 0 or not vim.api.nvim_win_is_valid(win) then M.show() else M.hide() end end

function M.start()
  M.running = true                                  -- take ownership
  height = 1                                        -- reset animation
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {}) -- clear buffer

  M.show()
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

  vim.schedule(function()
    vim.api.nvim_buf_set_lines(
      buf,
      -1,
      -1,
      false,
      err_lines
    )

    vim.api.nvim_buf_set_extmark(buf, ns, height, 0, {
      end_row = height + #err_lines,
      hl_group = "WarningMsg",
    })

    height = height + #err_lines

    vim.api.nvim_buf_set_lines(
      buf,
      -1,
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

return M
