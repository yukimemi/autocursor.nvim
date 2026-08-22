local M = {}

---@class autocursor.CursorState
---@field option "cursorline"|"cursorcolumn"
---@field enable boolean Whether the events may switch this option.
---@field state boolean  Value autocursor last applied; resynced by `fix_state`.
---@field events { name: string, set: boolean, wait: integer }[]

M.cursorline = { option = "cursorline", enable = true, state = false, events = {} }
M.cursorcolumn = { option = "cursorcolumn", enable = true, state = false, events = {} }

local by_option = { cursorline = M.cursorline, cursorcolumn = M.cursorcolumn }

-- Throttle bookkeeping, one slot per option: { timer = uv_timer|nil, time = ms }.
local throttles = {}

---Run `fn` right away when more than `delay + wait` ms passed since the last
---leading-edge run; otherwise (re)schedule it that far ahead so a burst of
---events collapses into a single switch. `time` deliberately tracks only the
---leading edge: the first event after a quiet spell is never delayed.
---@param id string
---@param fn fun()
---@param delay integer
---@param wait integer
local function throttle(id, fn, delay, wait)
  local t = throttles[id]
  if not t then
    t = { timer = nil, time = 0 }
    throttles[id] = t
  end
  if t.timer then
    t.timer:stop()
    t.timer:close()
    t.timer = nil
  end
  local threshold = delay + wait
  local now = vim.uv.now()
  if now - t.time > threshold then
    t.time = now
    fn()
  else
    t.timer = vim.defer_fn(function()
      t.timer = nil
      fn()
    end, threshold)
  end
end

---Throttled `set {option}` / `set no{option}`.
---@param option "cursorline"|"cursorcolumn"
---@param set boolean
---@param wait? integer Extra delay (ms) contributed by the triggering event.
function M.set_option(option, set, wait)
  local c = by_option[option]
  if not c then
    return
  end
  local options = require("autocursor.config").options
  throttle(option, function()
    local log = require("autocursor.log")
    if set == c.state or not c.enable then
      log.debug(("skip %s: state=%s enable=%s"):format(option, tostring(c.state), tostring(c.enable)))
      return
    end
    local ft = vim.bo.filetype
    if vim.tbl_contains(options.ignore_filetypes or {}, ft) then
      log.debug(("skip %s: filetype '%s' is ignored"):format(option, ft))
      return
    end
    c.state = set
    -- No scope in `opts`: behaves like `:set`, i.e. this window plus the
    -- default for the next one, which is what the denops version did.
    vim.api.nvim_set_option_value(option, set, {})
    log.info(("set %s%s"):format(set and "" or "no", option))
  end, options.throttle, wait or 0)
end

---Turn automatic switching on or off for one option. Disabling clears the
---option immediately; enabling hands control back to the events.
---@param option "cursorline"|"cursorcolumn"
---@param enable boolean
function M.change(option, enable)
  local c = by_option[option]
  if not c then
    return
  end
  if not enable then
    vim.api.nvim_set_option_value(option, false, {})
    c.state = false
  end
  c.enable = enable
  require("autocursor.log").debug(("%s: auto switching %s"):format(option, enable and "on" or "off"))
end

---Resync the tracked state with the real option values. Without this an
---external `:set cursorline` (colorscheme, another plugin, the user) would
---wedge the `set == state` short-circuit until the next opposite event.
function M.fix_state()
  M.cursorline.state = vim.api.nvim_get_option_value("cursorline", { win = 0 })
  M.cursorcolumn.state = vim.api.nvim_get_option_value("cursorcolumn", { win = 0 })
end

---Cancel throttled switches that have not fired yet and forget the throttle
---history, so neither a teardown nor a re-`setup()` lands a stale switch on
---the new configuration — and the first event after it is a leading edge.
function M.reset()
  for id, t in pairs(throttles) do
    if t.timer then
      t.timer:stop()
      t.timer:close()
    end
    throttles[id] = nil
  end
end

local fix_timer = nil

function M.stop_fix_timer()
  if fix_timer then
    fix_timer:stop()
    fix_timer:close()
    fix_timer = nil
  end
end

---(Re)start the resync timer. Idempotent; `interval <= 0` leaves it off.
---@param interval integer
function M.start_fix_timer(interval)
  M.stop_fix_timer()
  if not interval or interval <= 0 then
    return
  end
  fix_timer = vim.uv.new_timer()
  fix_timer:start(
    interval,
    interval,
    vim.schedule_wrap(function()
      M.fix_state()
    end)
  )
end

---Rebuild the tracked cursors from the current config.
function M.reload()
  M.reset()
  local options = require("autocursor.config").options
  for _, c in ipairs({ M.cursorline, M.cursorcolumn }) do
    local cfg = options[c.option]
    c.enable = cfg.enable
    c.events = cfg.events
  end
  M.fix_state()
end

return M
