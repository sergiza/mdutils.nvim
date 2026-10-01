local util = require("mdutils.util")
local opener = require("mdutils.opener")
local openAt = require("mdutils.openAt")

local M = {}

-- Extensions routed to the media player (seekable by timestamp).
M.media_extensions = {}
for _, ext in ipairs({
    ".mp4", ".mkv", ".webm", ".mov", ".avi", ".flv", ".wmv", ".m4v", ".mpg", ".mpeg",
    ".mp3", ".flac", ".wav", ".m4a", ".aac", ".ogg", ".opus",
}) do
    M.media_extensions[ext] = true
end

-- One command that dispatches the link under the cursor to the right handler:
--   #anchor          → jump to that header in this buffer
--   file#anchor      → open file, then jump to that header (text files only)
--   http(s)://...    → xdg-open (browser / desktop default)
--   .md/.txt/no-ext  → edit in nvim
--   .pdf             → PDF viewer      ->  at the trailing page num  if given
--   video/audio      → media player    ->  at the trailing timestamp if given
--   anything else    → xdg-open (desktop default)
function M.run()
    local line = vim.api.nvim_get_current_line()
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2] + 1

    local entry = util.link_under_cursor(line, cursor_col)
    if not entry or entry.link == "" then
        vim.notify("Mdutils: no markdown link on this line", vim.log.levels.WARN)
        return
    end

    local target = entry.link

    if util.is_url(target) then
        vim.fn.jobstart({ "xdg-open", target }, { detach = true })
        return
    end

    local path, anchor = util.split_anchor(target)
    if path == "" then
        if anchor then opener.goto_header(anchor) end
        return
    end

    local function edit(p)
        vim.cmd("edit " .. vim.fn.fnameescape(p))
        if anchor and anchor ~= "" then opener.goto_header(anchor) end
    end

    local resolved = util.resolve_path(path)
    local ts, page = openAt.parse_trailing_arg(line:sub(entry.stop + 1))

    local ext = (resolved:match("^.+(%..+)$") or ""):lower()
    if opener.text_extensions[ext] then
        edit(resolved)
    elseif openAt.is_pdf(resolved) then
        openAt.open_pdf(resolved, page and tonumber(page))
    elseif M.media_extensions[ext] then
        openAt.open_media(resolved, ts)
    elseif util.is_text_file(resolved) then
        edit(resolved)
    else
        vim.fn.jobstart({ "xdg-open", resolved }, { detach = true })
    end
end

return M
