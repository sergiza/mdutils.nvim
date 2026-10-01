local M = {}

local COMMANDS = {
    openLink   = "mdutils.openLink",
    todo       = "mdutils.todo",
    openAt     = "mdutils.openAt",
    opener     = "mdutils.opener",
}

function M.setup()
    vim.api.nvim_create_user_command("Mdutils", function(opts)
        local mod = COMMANDS[opts.args]
        if not mod then
            vim.notify("Mdutils: unknown command '" .. opts.args .. "'", vim.log.levels.ERROR)
            return
        end
        require(mod).run()
    end, {
        nargs = 1,
        complete = function()
            local keys = vim.tbl_keys(COMMANDS)
            table.sort(keys)
            return keys
        end,
    })
end

return M
