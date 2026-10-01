local M = {}

-- [ ] → [-] → [X] → [ ]
local NEXT = { [" "] = "-", ["-"] = "X", ["X"] = " ", ["x"] = " " }

function M.run()
    local line = vim.api.nvim_get_current_line()
    local prefix, state, rest = line:match("^(%s*%- %[)(.)(%].*)$")
    if prefix and NEXT[state] then
        vim.api.nvim_set_current_line(prefix .. NEXT[state] .. rest)
    end
end

return M
