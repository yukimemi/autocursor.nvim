local M = {}

---Configure autocursor and start switching `cursorline` / `cursorcolumn` on
---the configured events. The `:{Enable,Disable}AutoCursor*` commands work
---without this; only the autocmds need `setup()`.
---@param opts? autocursor.Options
function M.setup(opts)
  require("autocursor.config").setup(opts)
  require("autocursor.command").register()
  require("autocursor.autocmd").register()
end

-- Convenience Lua API mirroring the commands.

---@param option "cursorline"|"cursorcolumn"
function M.enable(option)
  require("autocursor.cursor").change(option, true)
end

---@param option "cursorline"|"cursorcolumn"
function M.disable(option)
  require("autocursor.cursor").change(option, false)
end

return M
