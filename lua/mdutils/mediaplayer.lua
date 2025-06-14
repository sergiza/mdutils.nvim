local M = {}

function M.run()
  local line = vim.api.nvim_get_current_line()
  local pattern = "%((.-)%)%s+(%d%d:%d%d:%d%d)"
  local path, time = line:match(pattern)

  if path and time then
    path = path:gsub("%%20", " ")
    os.execute('mpv --start=' .. time .. ' "' .. path .. '" >/dev/null 2>&1 &')
  else
    vim.notify("Invalid video path or timestamp format on this line.", vim.log.levels.WARN)
  end
end

return M
