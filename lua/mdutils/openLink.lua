local util = require("mdutils.util")

local M = {}

M.text_extensions = {
    [".md"] = true,
    [".txt"] = true,
    [""] = true,
}

local function slugify(text)
    return text
        :lower()
        :gsub("%s+", "-")
        :gsub("[^%w%-]", "")
end

-- Jump to the first ATX header ("## Title") whose slug matches the anchor,
-- skipping lines inside ``` / ~~~ code fences.
function M.goto_header(anchor)
    local want = slugify(anchor)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local in_fence = false
    for i, line in ipairs(lines) do
        if line:match("^%s*```") or line:match("^%s*~~~") then
            in_fence = not in_fence
        elseif not in_fence then
            local title = line:match("^#+%s+(.-)%s*#*%s*$")
            if title and slugify(title) == want then
                vim.api.nvim_win_set_cursor(0, { i, 0 })
                vim.cmd("normal! zz")
                return
            end
        end
    end
    util.notify("header not found: #" .. anchor, vim.log.levels.WARN)
end

-- Open a file in nvim and, if given, jump to the header anchor.
function M.edit(path, anchor)
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    if anchor and anchor ~= "" then M.goto_header(anchor) end
end

function M.run()
    local entry = util.current_link()
    if not entry then return end

    if util.is_url(entry.link) then
        util.xdg_open(entry.link)
        return
    end

    local path, anchor = util.split_anchor(entry.link)
    if path == "" then
        if anchor then M.goto_header(anchor) end
        return
    end

    local resolved = util.resolve_path(path)
    if M.text_extensions[util.extension(resolved)] or util.is_text_file(resolved) then
        M.edit(resolved, anchor)
    else
        util.xdg_open(resolved)
    end
end

return M
