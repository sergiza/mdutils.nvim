local M = {}

-- Parse [label](path) and optional trailing arg:
--   • timestamp    "HH:MM:SS" or "MM:SS"
--   • page number  num
local function parse_link_and_arg(line)
    local b1, e1 = line:find("%b[]")
    if not b1 then return nil end

    local b2, e2 = line:find("%b()", e1 + 1)
    if not b2 then return nil end

    local label = line:sub(b1 + 1, e1 - 1)
    local path  = line:sub(b2 + 1, e2 - 1)

    local after = line:sub(e2 + 1)
    local timestamp = after:match("^%s*(%d?%d:%d%d:%d%d)") or after:match("^%s*(%d?%d:%d%d)")
    local page = not timestamp and after:match("^%s*(%d+)%s*$") or nil

    return label, path, timestamp, page
end

local function is_url(p)
    return p:match("^%a[%w+.-]*://") ~= nil
end

local function decode_spaces_for_local(p)
    if is_url(p) then return p end
    return (p:gsub("%%20", " "))
end

local function resolve_path(path)
    path = decode_spaces_for_local(path)
    if is_url(path) or path:match("^/") then return path end
    local base = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:h")
    return vim.fn.fnamemodify(base .. "/" .. path, ":p")
end

local function is_pdf(path)
    return path:match("%.[Pp][Dd][Ff]$") ~= nil
end

local PDF_VIEWERS = {
    { "zathura",  "--page"        },
    { "evince",   "--page-index"  },
    { "okular",   "--page"        },
    { "xdg-open", nil             },
}

local MEDIA_PLAYERS = {
    { "vlc",      "--start-time", true  },  -- expects seconds
    { "mpv",      "--start",      false },  -- expects HH:MM:SS
    { "xdg-open", nil,            false },
}

local function find_software(list)
    for _, v in ipairs(list) do
        if vim.fn.executable(v[1]) == 1 then
            return v[1], v[2], v[3]
        end
    end
    return nil, nil, nil
end

-- CONVERTER: "HH:MM:SS" (or "MM:SS") -> seconds
local function ts_to_seconds(ts)
    local h, m, s = ts:match("^(%d+):(%d+):(%d+)$")
    if not h then
        h = "0"
        m, s = ts:match("^(%d+):(%d+)$")
    end
    return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
end

local function open_pdf(resolved, page)
    local viewer, page_flag = find_software(PDF_VIEWERS)
    if not viewer then
        vim.notify("Mdutils openAt: no PDF viewer found.", vim.log.levels.ERROR)
        return
    end

    local cmd = { viewer }
    if page and page_flag then
        table.insert(cmd, page_flag)
        table.insert(cmd, tostring(page))
    end
    table.insert(cmd, resolved)

    local msg = ("Opening PDF with %s → %s"):format(viewer, resolved)
    if page and page_flag then msg = msg .. (" (page %d)"):format(page) end
    vim.notify(msg, vim.log.levels.INFO)

    vim.fn.jobstart(cmd, {
        detach = true,
        stderr_buffered = true,
        on_exit = function(_, code, _)
            if code ~= 0 then
                vim.notify(viewer .. " exited with code " .. tostring(code), vim.log.levels.ERROR)
            end
        end,
    })
end

local function open_media(resolved, ts)
    local player, ts_flag, wants_seconds = find_software(MEDIA_PLAYERS)
    if not player then
        vim.notify("Mdutils openAt: no media player found.", vim.log.levels.ERROR)
        return
    end

    local cmd = { player }
    if ts and ts_flag then
        local value = wants_seconds and tostring(ts_to_seconds(ts)) or ts
        table.insert(cmd, ts_flag .. "=" .. value)
    end
    if ts_flag then table.insert(cmd, "--") end
    table.insert(cmd, resolved)

    local msg = ("Opening media with %s → %s"):format(player, resolved)
    if ts and ts_flag then msg = msg .. (" at %s"):format(ts) end
    vim.notify(msg, vim.log.levels.INFO)

    vim.fn.jobstart(cmd, {
        detach = true,
        stderr_buffered = true,
        on_exit = function(_, code, _)
            if code ~= 0 and code ~= 4 then
                vim.notify(player .. " exited with code " .. tostring(code), vim.log.levels.ERROR)
            end
        end,
    })
end

function M.run()
    local line = vim.api.nvim_get_current_line()
    local _, path, ts, page = parse_link_and_arg(line)

    if not path or path == "" then
        vim.notify("Mdutils openAt: no markdown link on this line", vim.log.levels.WARN)
        return
    end

    local resolved = resolve_path(path)

    if is_pdf(resolved) then
        open_pdf(resolved, page and tonumber(page))
    else
        open_media(resolved, ts)
    end
end

return M
