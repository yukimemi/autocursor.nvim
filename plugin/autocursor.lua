-- Eager registration so the `:{Enable,Disable}AutoCursor*` commands work
-- without calling `require("autocursor").setup()` (convention over
-- configuration). The event autocmds only start from `setup()`.
if vim.g.loaded_autocursor then
  return
end
vim.g.loaded_autocursor = true

require("autocursor.command").register()
