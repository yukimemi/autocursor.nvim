local M = {}

---Register the `:{Enable,Disable}AutoCursor{Line,Column}` commands. The names
---match the denops version so existing mappings keep working. Safe to call
---more than once.
function M.register()
  local function cmd(name, option, enable, desc)
    vim.api.nvim_create_user_command(name, function()
      require("autocursor.cursor").change(option, enable)
    end, { desc = desc })
  end

  cmd("EnableAutoCursorLine", "cursorline", true, "autocursor: switch cursorline automatically")
  cmd("DisableAutoCursorLine", "cursorline", false, "autocursor: stop switching cursorline (and clear it)")
  cmd("EnableAutoCursorColumn", "cursorcolumn", true, "autocursor: switch cursorcolumn automatically")
  cmd("DisableAutoCursorColumn", "cursorcolumn", false, "autocursor: stop switching cursorcolumn (and clear it)")
end

return M
