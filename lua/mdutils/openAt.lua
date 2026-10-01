local util = require("mdutils.util")

local M = {}

local PDF_VIEWERS = {
    { "zathura",  "--page"        },
    { "evince",   "--page-index"  },
    { "okular",   "--page"        },
    { "xdg-open", nil             },
}

local MEDIA_PLAYERS = {
    { "mpv",      "--start",      false },  -- expects HH:MM:SS
    { "vlc",      "--start-time", true  },  -- expects seconds
    { "xdg-open", nil,            false },
}

-- Parse the optional trailing arg after a link:
--   • timestamp    "HH:MM:SS" or "MM:SS"  → returned as string
--   • page number  num                    → returned as number
function M.parse_trailing_arg(after)
    local timestamp = after:match("^%s*(%d?%d:%d%d:%d%d)") or after:match("^%s*(%d?%d:%d%d)")
    local page = not timestamp and tonumber(after:match("^%s*(%d+)%s*$")) or nil
    return timestamp, page
end

local function find_software(list)
    for _, v in ipairs(list) do
        if vim.fn.executable(v[1]) == 1 then
            return v[1], v[2], v[3]
        end
    end
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

-- Run cmd detached, reporting non-zero exit codes not listed in ok_codes.
local function spawn(cmd, ok_codes)
    vim.fn.jobstart(cmd, {
        detach = true,
        on_exit = function(_, code)
            if code ~= 0 and not (ok_codes and ok_codes[code]) then
                util.notify(cmd[1] .. " exited with code " .. code, vim.log.levels.ERROR)
            end
        end,
    })
end

function M.open_pdf(resolved, page)
    local viewer, page_flag = find_software(PDF_VIEWERS)
    if not viewer then
        util.notify("no PDF viewer found", vim.log.levels.ERROR)
        return
    end

    local cmd = { viewer }
    local msg = ("Opening PDF with %s → %s"):format(viewer, resolved)
    if page and page_flag then
        vim.list_extend(cmd, { page_flag, tostring(page) })
        msg = msg .. (" (page %d)"):format(page)
    end
    table.insert(cmd, resolved)

    util.notify(msg)
    spawn(cmd)
end

function M.open_media(resolved, ts)
    local player, ts_flag, wants_seconds = find_software(MEDIA_PLAYERS)
    if not player then
        util.notify("no media player found", vim.log.levels.ERROR)
        return
    end

    local cmd = { player }
    local msg = ("Opening media with %s → %s"):format(player, resolved)
    if ts and ts_flag then
        local value = wants_seconds and tostring(ts_to_seconds(ts)) or ts
        table.insert(cmd, ts_flag .. "=" .. value)
        msg = msg .. (" at %s"):format(ts)
    end
    if ts_flag then table.insert(cmd, "--") end
    table.insert(cmd, resolved)

    util.notify(msg)
    spawn(cmd, { [4] = true })  -- mpv exits 4 when quit via signal/window close
end

function M.run()
    local entry, line = util.current_link()
    if not entry then return end

    local ts, page = M.parse_trailing_arg(line:sub(entry.stop + 1))
    local resolved = util.resolve_path(entry.link)

    if util.extension(resolved) == ".pdf" then
        M.open_pdf(resolved, page)
    else
        M.open_media(resolved, ts)
    end
end

return M
