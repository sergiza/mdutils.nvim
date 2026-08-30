local M = {}

function M.is_url(p)
    return p:match("^%a[%w+.-]*://") ~= nil
end

-- Find every [label](link) on a line, with its column span.
-- Returns a list of { start, stop, label, link } (1-based, inclusive).
function M.find_links(line)
    local links = {}
    for s, _, label, link in line:gmatch("()()%[(.-)%]%((.-)%)") do
        table.insert(links, {
            start = s,
            stop  = s + #label + #link + 3,
            label = label,
            link  = link,
        })
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
