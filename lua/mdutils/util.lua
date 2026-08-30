local M = {}

function M.is_url(p)
    return p:match("^%a[%w+.-]*://") ~= nil
end

-- Find every [label](link) on a line, with its column span.
-- Uses balanced matching so parens inside the link (e.g. "(no take)") don't
-- truncate it. Returns a list of { start, stop, label, link } (1-based, inclusive).
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

-- Resolve a link's path: URLs pass through, local paths get ~/$VAR expanded,
-- %20 decoded, and are made absolute relative to the current buffer's dir.
function M.resolve_path(path)
    if M.is_url(path) then return path end
    local p = vim.fn.expand(path):gsub("%%20", " ")
    if p:sub(1, 1) == "/" then return p end
    local base = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:h")
    return vim.fn.fnamemodify(base .. "/" .. p, ":p")
end

return M
