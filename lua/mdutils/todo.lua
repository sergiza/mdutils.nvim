local M = {}

function M.run()
  local line = vim.api.nvim_get_current_line()
  local new_line = line

  if line:find("^%s*%- %[ %]") then
    new_line = line:gsub("^(%s*%-) %[ %]", "%1 [-]", 1)
  elseif line:find("^%s*%- %[%-%]") then
    new_line = line:gsub("^(%s*%-) %[%-%]", "%1 [X]", 1)
  elseif line:find("^%s*%- %[[Xx]%]") then
    new_line = line:gsub("^(%s*%-) %[[Xx]%]", "%1 [ ]", 1)
  end

  if new_line ~= line then
    vim.api.nvim_set_current_line(new_line)
  end
end

return M
