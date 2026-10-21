local M = {}

function M.is_url(p)
    return p:match("^%a[%w+.-]*://") ~= nil
end

-- returns true if non-binary text file
function M.is_text_file(path)
    if vim.fn.executable("file") == 0 or vim.fn.filereadable(path) == 0 then
        return false
    end
    local enc = vim.fn.system({ "file", "--mime-encoding", "-b", path }):gsub("%s+", "")
    return enc ~= "" and enc ~= "binary"
end

-- Find every [label](link) on a line, with its column span.
-- Returns a list of { start, stop, label, link }
function M.find_links(line)
    local links = {}
    local pos = 1
    while true do
        local b1, e1 = line:find("%b[]", pos)
        if not b1 then break end
        -- the "(...)" must immediately follow the "]"
        local b2, e2 = line:find("^%b()", e1 + 1)
        if b2 then
            table.insert(links, {
                start = b1,
                stop  = e2,
                label = line:sub(b1 + 1, e1 - 1),
                link  = line:sub(b2 + 1, e2 - 1),
            })
            pos = e2 + 1
        else
            pos = e1 + 1
        end
    end
    return links
end

-- Pick the link under the cursor column, falling back to the first link.
function M.link_under_cursor(line, col)
    local links = M.find_links(line)
    for _, entry in ipairs(links) do
        if col >= entry.start and col <= entry.stop then
            return entry
        end
    end
    return links[1]
end

-- Link under the cursor on the current line, plus the line itself.
-- Returns nil when there is no (non-empty) link.
function M.current_link()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1
    local entry = M.link_under_cursor(line, col)
    if not entry or entry.link == "" then
        -- M.notify("no markdown link on this line", vim.log.levels.WARN)
        return nil
    end
    return entry, line
end

-- Lowercased extension with the dot (".md"), or "" when there is none.
function M.extension(path)
    local ext = vim.fn.fnamemodify(path, ":e")
    return ext == "" and "" or "." .. ext:lower()
end

-- Open with the OS default handler (xdg-open, open, start, ...).
function M.system_open(target)
    local _, err = vim.ui.open(target)
    if err then M.notify(err, vim.log.levels.ERROR) end
end

-- Locate a program: on $PATH first, then (macOS) inside <app>.app bundles,
-- which aren't on $PATH. Returns the command to run, or nil.
function M.find_executable(name, app)
    if vim.fn.executable(name) == 1 then return name end
    if not app or vim.fn.has("mac") == 0 then return nil end
    for _, dir in ipairs({ "/Applications", vim.fn.expand("~/Applications") }) do
        local path = ("%s/%s.app/Contents/MacOS/%s"):format(dir, app, app)
        if vim.fn.executable(path) == 1 then return path end
    end
end

-- ATX headers ("## Title") outside ``` / ~~~ code fences.
-- Returns a list of { lnum, level, text }, text without closing "#"s.
function M.headers(lines)
    local headers = {}
    local fence -- marker that opened the current fence, if inside one
    for lnum, line in ipairs(lines) do
        local marker = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
        if marker then
            if not fence then
                fence = marker
            elseif marker:sub(1, 1) == fence:sub(1, 1) and #marker >= #fence then
                fence = nil
            end
        elseif not fence then
            local hashes, text = line:match("^(#+)%s+(.-)%s*$")
            if hashes and #hashes <= 6 then
                text = text:gsub("%s+#+$", ""):gsub("^#+$", "")
                table.insert(headers, { lnum = lnum, level = #hashes, text = text })
            end
        end
    end
    return headers
end

function M.notify(msg, level)
    vim.notify("Mdutils: " .. msg, level or vim.log.levels.INFO)
end

-- Split "path#anchor" on the first unescaped "#". "\#" stays a literal "#"
-- in the path. Returns path, anchor (anchor is nil when there is none).
--   "README.md#links"  → "README.md", "links"
--   "#links"           → "", "links"
--   "a\#b.md"          → "a#b.md", nil
function M.split_anchor(target)
    local i = 1
    while i <= #target do
        local c = target:sub(i, i)
        if c == "\\" and target:sub(i + 1, i + 1) == "#" then
            i = i + 2
        elseif c == "#" then
            return target:sub(1, i - 1):gsub("\\#", "#"), target:sub(i + 1)
        else
            i = i + 1
        end
    end
    return (target:gsub("\\#", "#")), nil
end

-- Decode %XX escapes ("%20" → " ").
function M.url_decode(s)
    return (s:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end))
end

-- Resolve a link's path: URLs pass through, local paths get ~/$VAR expanded,
-- %XX decoded, and are made absolute relative to the current buffer's dir.
function M.resolve_path(path)
    if M.is_url(path) then return path end
    local p = M.url_decode(vim.fs.normalize(path))
    if p:sub(1, 1) == "/" then return p end
    local base = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:h")
    return vim.fn.fnamemodify(base .. "/" .. p, ":p")
end

return M
