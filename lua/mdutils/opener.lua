local M = {}

M.text_extensions = {
  [".md"] = true,
  [".txt"] = true,
  [""] = true,
}

function M.run()
  local line = vim.api.nvim_get_current_line()
  local cursor_col = vim.api.nvim_win_get_cursor(0)[2] + 1

  local candidates = {}
  for s, e, text, url in line:gmatch("()()%[(.-)%]%((.-)%)") do
    local start_col = s
    local end_col = e + #text + #url + 3
    table.insert(candidates, { start = start_col, stop = end_col, link = url })
  end

  if #candidates == 0 then return end

  local target
  for _, entry in ipairs(candidates) do
    if cursor_col >= entry.start and cursor_col <= entry.stop then
      target = entry.link
      break
    end
  end
  if not target then target = candidates[1].link end
  if not target or target == "" then return end

  local is_url = target:match("^https?://")
  local full_path = target

  if not is_url then
    local expanded = vim.fn.expand(target):gsub("%%20", " ")
    if expanded:sub(1, 1) == "/" then
      full_path = expanded
    else
      full_path = vim.fn.fnamemodify(vim.fn.expand('%:p:h') .. '/' .. expanded, ':p')
    end
  end

  local ext = full_path:match("^.+(%..+)$") or ""
  if M.text_extensions[ext] then
    vim.cmd("edit " .. vim.fn.fnameescape(full_path))
  else
    -- vim.fn.jobstart("xdg-open '" .. full_path .. "'", { detach = true, shell = true })
    vim.fn.jobstart({ "xdg-open", full_path }, { detach = true })
  end
end

return M
