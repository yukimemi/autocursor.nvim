local M = {}

---@class autocursor.Event
---@field name string|string[] Autocmd event (or events) that triggers the switch.
---@field set boolean          true = `set {option}`, false = `set no{option}`.
---@field wait integer         Extra delay (ms) added to the throttle window for this event.

---@class autocursor.Cursor
---@field enable boolean            Whether the option is switched automatically.
---@field events autocursor.Event[] Events driving the option.

---@class autocursor.Options
---@field notify boolean       Emit `vim.notify` when an option is switched (gated by `log_level`). Default false.
---@field log_level "trace"|"debug"|"info"|"warn"|"error" Minimum severity surfaced when `notify = true`.
---@field throttle integer     Throttle window (ms); events landing inside it collapse into one switch. Default 300.
---@field fix_interval integer Interval (ms) to resync the tracked state with the real options. 0 disables it.
---@field ignore_filetypes string[] Filetypes whose windows are never touched.
---@field cursorline autocursor.Cursor
---@field cursorcolumn autocursor.Cursor

---Both options share the same default shape: idle turns them on, moving turns
---them off. The extra `wait` on the idle events keeps a short pause from
---flashing the highlight.
---@param wait integer
---@return autocursor.Event[]
local function default_events(wait)
  return {
    { name = { "CursorHold", "CursorHoldI" }, set = true, wait = wait },
    { name = { "WinEnter", "BufEnter" }, set = true, wait = 0 },
    { name = { "CursorMoved", "CursorMovedI" }, set = false, wait = 0 },
  }
end

M.defaults = {
  notify = false,
  log_level = "warn",
  throttle = 300,
  fix_interval = 5000,
  ignore_filetypes = {
    "ctrlp",
    "ddu-ff",
    "ddu-ff-filter",
    "ddu-filer",
    "dpswalk",
    "list",
    "qf",
    "quickfix",
  },
  cursorline = { enable = true, events = default_events(100) },
  cursorcolumn = { enable = true, events = default_events(100) },
}

M.options = vim.deepcopy(M.defaults)

---Flatten `name` lists into one entry per event and drop duplicates, so the
---same event never registers the same switch twice.
---@param events autocursor.Event[]
---@return { name: string, set: boolean, wait: integer }[]
local function normalize(events)
  local seen, out = {}, {}
  for _, e in ipairs(events or {}) do
    local names = type(e.name) == "table" and e.name or { e.name }
    local set = e.set and true or false
    local wait = e.wait or 0
    for _, name in ipairs(names) do
      local key = ("%s\0%s\0%d"):format(name, tostring(set), wait)
      if not seen[key] then
        seen[key] = true
        out[#out + 1] = { name = name, set = set, wait = wait }
      end
    end
  end
  return out
end

---A user `events` list replaces the default one wholesale (deep-extend merges
---lists by index, which would splice the two together).
---@param opts? autocursor.Options
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  for _, option in ipairs({ "cursorline", "cursorcolumn" }) do
    M.options[option].events = normalize(M.options[option].events)
  end
end

return M
