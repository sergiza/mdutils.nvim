local util = require("mdutils.util")
local openAt = require("mdutils.openAt")

local M = {}

-- Extensions edited in nvim without checking the file's contents.
M.text_extensions = {
    [".md"] = true,
    [".txt"] = true,
    [""] = true,
}

-- Extensions routed to the media player (seekable by timestamp).
M.media_extensions = {}
for _, ext in ipairs({
    ".mp4", ".mkv", ".webm", ".mov", ".avi", ".flv", ".wmv", ".m4v", ".mpg", ".mpeg",
    ".mp3", ".flac", ".wav", ".m4a", ".aac", ".ogg", ".opus",
}) do
    M.media_extensions[ext] = true
end

local function slugify(text)
    return text
        :lower()
        :gsub("%s+", "-")
        :gsub("[^%w%-]", "")
end

-- Jump to the first header whose slug matches the anchor.
function M.goto_header(anchor)
    local want = slugify(anchor)
    for _, h in ipairs(util.headers(vim.api.nvim_buf_get_lines(0, 0, -1, false))) do
        if slugify(h.text) == want then
            vim.api.nvim_win_set_cursor(0, { h.lnum, 0 })
            vim.cmd("normal! zz")
            return
        end
    end
    util.notify("header not found: #" .. anchor, vim.log.levels.WARN)
end

-- Open a file in nvim and, if given, jump to the header anchor.
function M.edit(path, anchor)
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    if anchor and anchor ~= "" then M.goto_header(anchor) end
end

-- Dispatch the link under the cursor to the right handler:
--   #anchor          → jump to that header in this buffer
--   file#anchor      → open file, then jump to that header (text files only)
--   http(s)://...    → system default (browser)
--   .md/.txt/no-ext  → edit in nvim
--   .pdf             → PDF viewer      ->  at the trailing page num  if given
--   video/audio      → media player    ->  at the trailing timestamp if given
--   anything else    → system default app
function M.run()
    local entry, line = util.current_link()
    if not entry then return end

    if util.is_url(entry.link) then
        util.system_open(entry.link)
        return
    end

    local path, anchor = util.split_anchor(entry.link)
    if path == "" then
        if anchor then M.goto_header(anchor) end
        return
    end

    local resolved = util.resolve_path(path)
    local ts, page = openAt.parse_trailing_arg(line:sub(entry.stop + 1))
    local ext = util.extension(resolved)

    if M.text_extensions[ext] then
        M.edit(resolved, anchor)
    elseif ext == ".pdf" then
        openAt.open_pdf(resolved, page)
    elseif M.media_extensions[ext] then
        openAt.open_media(resolved, ts)
    elseif util.is_text_file(resolved) then
        M.edit(resolved, anchor)
    else
        util.system_open(resolved)
    end
end

return M
