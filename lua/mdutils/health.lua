local util = require("mdutils.util")
local openAt = require("mdutils.openAt")

local M = {}

local h = vim.health

-- Report the first program found in list, or warn with the fallback.
local function check_software(kind, list, fallback)
    for _, v in ipairs(list) do
        local exe = util.find_executable(v[1], v.app)
        if exe then
            h.ok(("%s: %s"):format(kind, exe))
            return
        end
    end
    local names = vim.tbl_map(function(v) return v[1] end, list)
    h.warn(("%s: none found (%s)"):format(kind, table.concat(names, ", ")), fallback)
end

function M.check()
    h.start("mdutils")

    if vim.fn.has("nvim-0.10") == 1 then
        h.ok("Neovim " .. tostring(vim.version()))
    else
        h.error("Neovim 0.10+ required (vim.ui.open)")
    end

    local fallback = "Opens with the system default app, without jumping to %s"
    check_software("PDF viewer", openAt.PDF_VIEWERS, fallback:format("the page"))
    check_software("Media player", openAt.MEDIA_PLAYERS, fallback:format("the timestamp"))
end

return M
