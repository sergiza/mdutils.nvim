local M = {}

function M.setup()
  local opener = require("mdutils.opener")
  local todo = require("mdutils.todo")
  local mediaplayer = require("mdutils.mediaplayer")

  vim.api.nvim_create_user_command("Mdutils", function(opts)
    local arg = opts.args
    if arg == "opener" then
      opener.open_link()
    elseif arg == "todo" then
      todo.run()
    elseif arg == "mediaplayer" then
      mediaplayer.run()
    else
      vim.notify("Subcomando inválido: " .. arg, vim.log.levels.ERROR)
    end
  end, { nargs = 1, complete = function()
    return { "opener", "todo", "mediaplayer" }
  end })
end

return M
