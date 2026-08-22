local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality

local COMMANDS = {
  "EnableAutoCursorLine",
  "DisableAutoCursorLine",
  "EnableAutoCursorColumn",
  "DisableAutoCursorColumn",
}

local function opt(name)
  return vim.api.nvim_get_option_value(name, { win = 0 })
end

local function fire(event)
  vim.api.nvim_exec_autocmds(event, { pattern = "*" })
end

local function wait_opt(name, value)
  return vim.wait(3000, function()
    return opt(name) == value
  end, 10)
end

---A single event per switch and no throttle window, so a case observes the
---result on the next loop tick instead of after the default 400 ms.
local function setup_fast(overrides)
  local events = {
    { name = "CursorHold", set = true, wait = 0 },
    { name = "CursorMoved", set = false, wait = 0 },
  }
  require("autocursor").setup(vim.tbl_deep_extend("force", {
    throttle = 0,
    fix_interval = 0,
    cursorline = { enable = true, events = events },
    cursorcolumn = { enable = true, events = events },
  }, overrides or {}))
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      require("autocursor.autocmd").unregister()
      vim.opt.cursorline = false
      vim.opt.cursorcolumn = false
      vim.bo.filetype = ""
      require("autocursor.config").setup()
    end,
    post_once = function()
      require("autocursor.autocmd").unregister()
    end,
  },
})

T["events switch cursorline on and off"] = function()
  setup_fast()
  fire("CursorHold")
  eq(wait_opt("cursorline", true), true)
  fire("CursorMoved")
  eq(wait_opt("cursorline", false), true)
end

T["the two options are switched independently"] = function()
  setup_fast({ cursorline = { enable = false } })
  fire("CursorHold")
  eq(wait_opt("cursorcolumn", true), true)
  eq(opt("cursorline"), false)
end

T["default events switch cursorline on CursorHold"] = function()
  require("autocursor").setup()
  fire("CursorHold")
  eq(wait_opt("cursorline", true), true)
end

T["ignored filetypes are left alone"] = function()
  setup_fast({ ignore_filetypes = { "qf" } })
  vim.bo.filetype = "qf"
  fire("CursorHold")
  vim.wait(300)
  eq(opt("cursorline"), false)
end

T["Disable clears the option and stops switching, Enable resumes"] = function()
  setup_fast()
  fire("CursorHold")
  eq(wait_opt("cursorline", true), true)

  vim.cmd("DisableAutoCursorLine")
  eq(opt("cursorline"), false)
  fire("CursorHold")
  vim.wait(300)
  eq(opt("cursorline"), false)

  vim.cmd("EnableAutoCursorLine")
  fire("CursorHold")
  eq(wait_opt("cursorline", true), true)
end

T["a burst inside the throttle window collapses into one delayed switch"] = function()
  setup_fast({ throttle = 200 })
  -- Leading edge: the first event after a quiet spell is applied at once.
  fire("CursorHold")
  eq(wait_opt("cursorline", true), true)

  fire("CursorMoved")
  fire("CursorMoved")
  vim.wait(80)
  eq(opt("cursorline"), true) -- still inside the window
  eq(wait_opt("cursorline", false), true) -- and applied once it closes
end

T["the resync timer picks up an external :set"] = function()
  setup_fast({ fix_interval = 50 })
  local cursor = require("autocursor.cursor")
  fire("CursorHold")
  eq(wait_opt("cursorline", true), true)
  eq(cursor.cursorline.state, true)

  vim.opt.cursorline = false -- changed behind autocursor's back
  eq(
    vim.wait(3000, function()
      return cursor.cursorline.state == false
    end, 10),
    true
  )
end

T["plugin/autocursor.lua registers the commands eagerly"] = function()
  for _, name in ipairs(COMMANDS) do
    pcall(vim.api.nvim_del_user_command, name)
    eq(vim.fn.exists(":" .. name), 0)
  end

  vim.g.loaded_autocursor = nil
  local path = vim.api.nvim_get_runtime_file("plugin/autocursor.lua", false)[1]
  eq(type(path), "string")
  vim.cmd.source(path)

  for _, name in ipairs(COMMANDS) do
    eq(vim.fn.exists(":" .. name), 2)
  end
end

return T
