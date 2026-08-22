local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      require("autocursor.config").setup()
    end,
  },
})

local function names(events)
  return vim.tbl_map(function(e)
    return e.name
  end, events)
end

T["defaults drive both options"] = function()
  local options = require("autocursor.config").options
  eq(options.throttle, 300)
  eq(options.fix_interval, 5000)
  eq(options.cursorline.enable, true)
  eq(options.cursorcolumn.enable, true)
  -- Three grouped defaults, two event names each.
  eq(names(options.cursorline.events), {
    "CursorHold",
    "CursorHoldI",
    "WinEnter",
    "BufEnter",
    "CursorMoved",
    "CursorMovedI",
  })
  eq(options.cursorline.events[1].set, true)
  eq(options.cursorline.events[1].wait, 100)
  eq(options.cursorline.events[5].set, false)
  eq(options.cursorline.events[5].wait, 0)
end

T["a user events list replaces the defaults and is flattened"] = function()
  require("autocursor.config").setup({
    cursorline = { events = { { name = { "FocusGained", "WinEnter" }, set = true, wait = 20 } } },
  })
  local events = require("autocursor.config").options.cursorline.events
  eq(names(events), { "FocusGained", "WinEnter" })
  eq(events[2], { name = "WinEnter", set = true, wait = 20 })
end

T["duplicate events collapse into one"] = function()
  require("autocursor.config").setup({
    cursorline = {
      events = {
        { name = { "WinEnter", "WinEnter" }, set = true, wait = 0 },
        { name = "WinEnter", set = true, wait = 0 },
        -- Same event, different switch: kept, it is a different rule.
        { name = "WinEnter", set = false, wait = 0 },
      },
    },
  })
  local events = require("autocursor.config").options.cursorline.events
  eq(#events, 2)
  eq(events[1].set, true)
  eq(events[2].set, false)
end

T["a partial table keeps every other default"] = function()
  require("autocursor.config").setup({ throttle = 10, cursorcolumn = { enable = false } })
  local options = require("autocursor.config").options
  eq(options.throttle, 10)
  eq(options.fix_interval, 5000)
  eq(options.cursorcolumn.enable, false)
  eq(#options.cursorcolumn.events, 6)
  eq(#options.cursorline.events, 6)
  eq(options.ignore_filetypes[1], "ctrlp")
end

T["`wait` and `set` default to 0 / false"] = function()
  require("autocursor.config").setup({
    cursorline = { events = { { name = "WinEnter" } } },
  })
  eq(require("autocursor.config").options.cursorline.events[1], { name = "WinEnter", set = false, wait = 0 })
end

T["setup leaves the defaults table untouched"] = function()
  require("autocursor.config").setup({ throttle = 1 })
  local defaults = require("autocursor.config").defaults
  eq(defaults.throttle, 300)
  -- Still the grouped (unflattened) form, i.e. setup worked on a copy.
  eq(type(defaults.cursorline.events[1].name), "table")
  eq(#defaults.cursorline.events, 3)
end

return T
