local util = require("mdutils.util")
local openLink = require("mdutils.openLink")
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
    local entry, line = util.current_link()
    if not entry then return end

    if util.is_url(entry.link) then
        util.xdg_open(entry.link)
        return
    end

    local path, anchor = util.split_anchor(entry.link)
    if path == "" then
        if anchor then openLink.goto_header(anchor) end
        return
    end

    local resolved = util.resolve_path(path)
    local ts, page = openAt.parse_trailing_arg(line:sub(entry.stop + 1))
    local ext = util.extension(resolved)

    if openLink.text_extensions[ext] then
        openLink.edit(resolved, anchor)
    elseif ext == ".pdf" then
        openAt.open_pdf(resolved, page)
    elseif M.media_extensions[ext] then
        openAt.open_media(resolved, ts)
    elseif util.is_text_file(resolved) then
        openLink.edit(resolved, anchor)
    else
        util.xdg_open(resolved)
    end
end

return M
