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
    -- NOTE: VLC uses --start-time which expects seconds, not HH:MM:SS.
    -- TODO: VLC support: HH:MM:SS to seconds converter
    { "mpv",      "--start"       },
    { "vlc",      "--start-time"  },
    { "xdg-open", nil             },
}

local function find_software(list)
    for _, v in ipairs(list) do
        if vim.fn.executable(v[1]) == 1 then
            return v[1], v[2]
        end
    end
    return nil, nil
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
    if page then msg = msg .. (" (page %d)"):format(page) end
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
    local player, ts_flag = find_software(MEDIA_PLAYERS)
    if not player then
        vim.notify("Mdutils openAt: no media player found.", vim.log.levels.ERROR)
        return
    end

    local cmd = { player, "--", resolved }
    if ts and ts_flag then table.insert(cmd, 2, ts_flag .. "=" .. ts) end

    local msg = ("Opening media with %s → %s"):format(player, resolved)
    if ts then msg = msg .. (" at %s"):format(ts) end
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
    local label, path, ts, page = parse_link_and_arg(line)

    if not path or path == "" then
        vim.notify("Mdutils openAt: no markdown link on this line", vim.log.levels.WARN)
        return
    end

    local resolved = resolve_path(path)
    local shown    = (label and label ~= "" and label) or path

    if is_pdf(resolved) then
        open_pdf(resolved, page and tonumber(page))
    else
        local msg = ("Opening '%s' → %s"):format(shown, resolved)
        if ts then msg = msg .. (" at %s"):format(ts) end
        vim.notify(msg, vim.log.levels.INFO)
        open_media(resolved, ts)
    end
end

return M
