local M = {}

-- [label](path) & optional timestamp "HH:MM:SS" or "MM:SS"
local function parse_link_and_ts(line)
  local b1, e1 = line:find("%b[]")
  if not b1 then return nil end

  local b2, e2 = line:find("%b()", e1 + 1)
  if not b2 then return nil end

  local label = line:sub(b1 + 1, e1 - 1)
  local path  = line:sub(b2 + 1, e2 - 1)

  -- everything after the closing ')'
  local after = line:sub(e2 + 1)
  local ts = after:match("^%s*(%d?%d:%d%d:%d%d)") or after:match("^%s*(%d?%d:%d%d)")

  return label, path, ts
end


-- %20 -> " "
local function is_url(p)
  return p:match("^%a[%w+.-]*://") ~= nil
end
local function decode_spaces_for_local(p)
  if is_url(p) then return p end
  return (p:gsub("%%20", " "))
end
local function resolve_path(path)
  path = decode_spaces_for_local(path)
  if is_url(path) or path:match("^/") then
    return path
  end
  local base = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:h")
  return vim.fn.fnamemodify(base .. "/" .. path, ":p")
end


function M.run()
  local line = vim.api.nvim_get_current_line()
  local label, path, ts = parse_link_and_ts(line)

  if not path or path == "" then
    vim.notify("Mdutils mediaplayer: no markdown link on this line", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("mpv") ~= 1 then
    vim.notify("Mdutils mediaplayer: 'mpv' not found in PATH", vim.log.levels.ERROR)
    return
  end

  local resolved = resolve_path(path)

  -- Notify
  local shown = (label and label ~= "" and label) or path
  local msg = ("Opening '%s' → %s"):format(shown, resolved)
  if ts then msg = msg .. (" at %s"):format(ts) end
  vim.notify(msg, vim.log.levels.INFO)

  -- Launch mpv
  local cmd = { "mpv", "--", resolved }
  if ts then table.insert(cmd, 2, "--start=" .. ts) end
  vim.fn.jobstart(cmd, {
    detach = true,
    on_stderr = function(_, data, _)
      if data and #data > 0 then
        local text = table.concat(vim.tbl_filter(function(s) return s and s ~= "" end, data), "\n")
        if text ~= "" then
          vim.notify("mpv: " .. text, vim.log.levels.WARN)
        end
      end
    end,
    on_exit = function(_, code, _)
      if code ~= 0 then
        vim.notify("mpv exited with code " .. tostring(code), vim.log.levels.ERROR)
      end
    end,
  })
end

return M
