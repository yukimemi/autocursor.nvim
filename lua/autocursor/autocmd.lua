local M = {}

local AUGROUP = "autocursor"

---Install one autocmd per configured event and start the resync timer.
---Idempotent: the augroup is cleared on re-setup.
function M.register()
  local cursor = require("autocursor.cursor")
  cursor.reload()

  local group = vim.api.nvim_create_augroup(AUGROUP, { clear = true })
  for _, c in ipairs({ cursor.cursorline, cursor.cursorcolumn }) do
    for _, e in ipairs(c.events) do
      vim.api.nvim_create_autocmd(e.name, {
        group = group,
        pattern = "*",
        -- The switch always targets the window the event fired in, which is
        -- the current one for every event autocursor is driven by.
        callback = function()
          cursor.set_option(c.option, e.set, e.wait)
        end,
      })
    end
  end

  cursor.start_fix_timer(require("autocursor.config").options.fix_interval)
end

function M.unregister()
  pcall(vim.api.nvim_del_augroup_by_name, AUGROUP)
  local cursor = require("autocursor.cursor")
  cursor.stop_fix_timer()
  cursor.reset()
end

return M
