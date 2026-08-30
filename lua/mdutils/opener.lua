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

function M.goto_header(anchor)
    local want = slugify(anchor)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i, line in ipairs(lines) do
        local title = line:match("^#+%s+(.+)$")
        if title and slugify(title) == want then
            vim.api.nvim_win_set_cursor(0, { i, 0 })
            vim.cmd("normal! zz")
            return
        end
    end
    vim.notify("mdutils: header not found: #" .. anchor, vim.log.levels.WARN)
end

function M.run()
    local line = vim.api.nvim_get_current_line()
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2] + 1

    local entry = util.link_under_cursor(line, cursor_col)
    if not entry then return end

    local target = entry.link
    if target == "" then return end

    if target:sub(1, 1) == "#" then
        M.goto_header(target:sub(2))
        return
    end

    local full_path = util.resolve_path(target)

    local ext = full_path:match("^.+(%..+)$") or ""
    if M.text_extensions[ext] or util.is_text_file(full_path) then
        vim.cmd("edit " .. vim.fn.fnameescape(full_path))
    else
        vim.fn.jobstart({ "xdg-open", full_path }, { detach = true })
    end
end

return M
