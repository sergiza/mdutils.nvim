local M = {}

function M.setup()
    vim.api.nvim_create_user_command("Mdutils", function(opts)
        local arg = opts.args
        if arg == "opener" then
            require("mdutils.opener").run()
        elseif arg == "todo" then
            require("mdutils.todo").run()
        elseif arg == "mediaplayer" then
            require("mdutils.mediaplayer").run()
        else
            vim.notify("Mdutils: unknown command '" .. arg .. "'", vim.log.levels.ERROR)
        end
    end, {
        nargs = 1,
        complete = function()
            return { "opener", "todo", "mediaplayer" }
        end,
    })
end

return M
