local M = {}

local TITLE = "Markdown headers"

-- qf strips leading spaces, not NBSP
local NBSP = "\194\160"

vim.api.nvim_set_hl(0, "MdutilsQfH1", { fg = "#ff9e64", bold = true, default = true })
vim.api.nvim_set_hl(0, "MdutilsQfH2", { fg = "#7dcfff", bold = true, default = true })
vim.api.nvim_set_hl(0, "MdutilsQfH3", { fg = "#9ece6a", default = true })
vim.api.nvim_set_hl(0, "MdutilsQfH4", { fg = "#bb9af7", default = true })
vim.api.nvim_set_hl(0, "MdutilsQfH5", { link = "MdutilsQfH4", default = true })
vim.api.nvim_set_hl(0, "MdutilsQfH6", { link = "MdutilsQfH4", default = true })

-- "fname|lnum col 1| " + indent + N hashes
local PATTERNS = {}
for level = 1, 6 do
    PATTERNS[level] = {
        "MdutilsQfH" .. level,
        [[\v^[^|]*\|[^|]*\| (%u00a0){]] .. 2 * (level - 1) .. [[}\zs#{]] .. level .. [[} .*$]],
    }
end

local function apply_matches()
    if vim.bo.buftype ~= "quickfix" then
        return
    end
    for _, id in ipairs(vim.w.mdutils_qf_match_ids or {}) do
        pcall(vim.fn.matchdelete, id)
    end
    vim.w.mdutils_qf_match_ids = nil
    if vim.fn.getqflist({ title = 1 }).title ~= TITLE then
        return
    end
    local ids = {}
    for _, p in ipairs(PATTERNS) do
        ids[#ids + 1] = vim.fn.matchadd(p[1], p[2])
    end
    vim.w.mdutils_qf_match_ids = ids
end

vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("MdutilsHeaders", { clear = true }),
    callback = apply_matches,
})

function M.run()
    local bufnr = vim.api.nvim_get_current_buf()
    -- called from the qf window: use the previous one
    if vim.bo[bufnr].buftype ~= "" then
        local prev = vim.fn.win_getid(vim.fn.winnr("#"))
        if prev ~= 0 then
            bufnr = vim.api.nvim_win_get_buf(prev)
        end
    end
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local items = {}
    local in_fence = false

    for lnum, line in ipairs(lines) do
        if line:match("^%s*```") or line:match("^%s*~~~") then
            in_fence = not in_fence
        elseif not in_fence then
            local hashes, text = line:match("^(#+)%s+(.*)")
            if hashes and #hashes <= 6 then
                table.insert(items, {
                    bufnr = bufnr,
                    lnum = lnum,
                    col = 1,
                    text = string.rep(NBSP .. NBSP, #hashes - 1) .. hashes .. " " .. text,
                })
            end
        end
    end

    if #items == 0 then
        vim.notify("No markdown headers found", vim.log.levels.INFO)
        return
    end

    vim.fn.setqflist({}, " ", { title = TITLE, items = items })
    vim.cmd("botright copen")
end

return M
