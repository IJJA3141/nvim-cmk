local M = {}

---@class cmk.PopUp
---@field buf integer
---@field win integer
---@field insert fun(data: string)
---@field close fun()

---@param max_height integer
---@param window_config vim.api.keyset.win_config
---@return cmk.PopUp
function M.create_popup(max_height, window_config)
  ---@type cmk.PopUp
  local popup = {}
  popup.buf = vim.api.nvim_create_buf(false, true)
  popup.win = vim.api.nvim_open_win(popup.buf, false, window_config)

  ---@param data string
  function popup.insert(data)
    -- add line
    local lines = {}
    for line in data:gmatch("[^\r\n]+") do
      table.insert(lines, line)
    end

    local height = vim.api.nvim_win_get_height(popup.win)
    vim.api.nvim_buf_set_lines(
      popup.buf,
      height == 1 and -2 or -1,
      -1,
      false,
      lines
    )

    if vim.api.nvim_win_is_valid(popup.win) then
      -- resize win / move
      if height < max_height then
        vim.api.nvim_win_set_height(popup.win, height + 1)
      end

      -- place cursor
      if vim.api.nvim_win_get_cursor(popup.win)[1] == height then
        vim.api.nvim_win_set_cursor(popup.win, { height + 1, 1 })
      end
    end
  end

  function popup.close()
    if vim.api.nvim_win_is_valid(popup.win) then
      vim.api.nvim_win_close(popup.win, false)
    end

    if vim.api.nvim_buf_is_valid(popup.buf) then
      vim.api.nvim_buf_delete(popup.buf, { force = true })
    end
  end

  return popup
end

return M
