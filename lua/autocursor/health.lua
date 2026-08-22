local M = {}

local h = vim.health
local start = h.start or h.report_start
local ok = h.ok or h.report_ok
local info = h.info or h.report_info
local warn = h.warn or h.report_warn

function M.check()
  start("autocursor")

  if vim.fn.has("nvim-0.10") == 1 then
    ok("Neovim >= 0.10")
  else
    warn("Neovim 0.10+ recommended (vim.uv)")
  end

  local options = require("autocursor.config").options
  local cursor = require("autocursor.cursor")

  if vim.fn.exists("#autocursor") == 1 then
    ok("autocmds installed (setup() has run)")
  else
    warn('no autocmds: call require("autocursor").setup()')
  end

  for _, c in ipairs({ cursor.cursorline, cursor.cursorcolumn }) do
    local names = {}
    for _, e in ipairs(c.events) do
      names[#names + 1] = ("%s%s"):format(e.set and "+" or "-", e.name)
    end
    info(
      ("%s: %s, %d events (%s)"):format(
        c.option,
        c.enable and "enabled" or "disabled",
        #c.events,
        #names > 0 and table.concat(names, " ") or "none"
      )
    )
  end

  info(("throttle: %dms"):format(options.throttle))
  info(options.fix_interval > 0 and ("state resync: every %dms"):format(options.fix_interval) or "state resync: off")
  info(("ignored filetypes: %s"):format(table.concat(options.ignore_filetypes or {}, ", ")))
  info(("notify: %s (log_level %s)"):format(tostring(options.notify), options.log_level))
end

return M
