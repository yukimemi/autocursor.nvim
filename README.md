<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/yukimemi/autocursor.nvim/main/assets/logo-dark.svg">
  <img src="https://raw.githubusercontent.com/yukimemi/autocursor.nvim/main/assets/logo.svg" alt="autocursor — cursorline that follows your pause" width="520">
</picture>

<p><em>cursorline that follows your pause.</em></p>

[![CI](https://github.com/yukimemi/autocursor.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/yukimemi/autocursor.nvim/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/yukimemi/autocursor.nvim/blob/main/LICENSE)
[![Neovim 0.10+](https://img.shields.io/badge/Neovim-0.10+-57A143?logo=neovim&logoColor=white)](https://neovim.io)

</div>

Light up `cursorline` / `cursorcolumn` when you stop moving, and drop them the
moment you start again — so the crosshair is there when you look for the
cursor, and out of the way while you edit. A pure-Lua, Neovim-only rewrite of
[autocursor.vim](https://github.com/yukimemi/autocursor.vim) (no Deno / denops
dependency).

## Requirements

- Neovim >= 0.10 (`vim.uv`)

## Install

With [rvpm](https://github.com/yukimemi/rvpm) (recommended):

```sh
rvpm add yukimemi/autocursor.nvim --on-event BufReadPre,BufNewFile --on-cmd '/^(Enable|Disable)AutoCursor.*$/'
```

Or in `config.toml`:

```toml
[[plugins]]
url = "https://github.com/yukimemi/autocursor.nvim"
on_event = ["BufReadPre", "BufNewFile"]
on_cmd = ["/^(Enable|Disable)AutoCursor.*$/"]
```

> rvpm doesn't auto-run `setup()` — and here that hook is **required**, not
> optional: the commands come up either way, but nothing is switched
> automatically until `setup()` installs the autocmds. Put
> `require("autocursor").setup()` (options optional) in
> `plugins/github.com/yukimemi/autocursor.nvim/after.lua`, or run
> `rvpm edit yukimemi/autocursor.nvim --after`.

Or with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "yukimemi/autocursor.nvim",
  event = "VeryLazy",
  opts = {},
}
```

`opts` is passed straight to `require("autocursor").setup()`. `VeryLazy`
rather than a buffer event: the switching should also be live in a window that
never reads a file (a dashboard, a scratch split).

## Configuration

Defaults:

```lua
require("autocursor").setup({
  notify = false,        -- vim.notify on every switch (gated by log_level)
  log_level = "warn",    -- "trace"|"debug"|"info"|"warn"|"error"
  throttle = 300,        -- ms; events landing inside the window collapse into one switch
  fix_interval = 5000,   -- ms; resync with the real options (external `:set`). 0 disables
  ignore_filetypes = { "ctrlp", "ddu-ff", "ddu-ff-filter", "ddu-filer", "dpswalk", "list", "qf", "quickfix" },
  cursorline = {
    enable = true,
    events = {
      { name = { "CursorHold", "CursorHoldI" }, set = true, wait = 100 },
      { name = { "WinEnter", "BufEnter" }, set = true, wait = 0 },
      { name = { "CursorMoved", "CursorMovedI" }, set = false, wait = 0 },
    },
  },
  cursorcolumn = {
    enable = true,
    events = {
      { name = { "CursorHold", "CursorHoldI" }, set = true, wait = 100 },
      { name = { "WinEnter", "BufEnter" }, set = true, wait = 0 },
      { name = { "CursorMoved", "CursorMovedI" }, set = false, wait = 0 },
    },
  },
})
```

An event entry is `{ name = <event or events>, set = <true|false>, wait = <ms> }`:
`set = true` does `set {option}`, `set = false` does `set no{option}`, and
`wait` is added to `throttle` for that event only — the delay before the switch
actually lands. A `name` list is expanded into one autocmd per event, and
duplicate `(name, set, wait)` triples are dropped.

A user `events` list **replaces** the default one, so write out every event you
want. Everything else can be given partially.

Filetypes in `ignore_filetypes` are never touched, which keeps pickers and
quickfix-ish windows from flickering.

## Commands

| Command | Action |
| --- | --- |
| `:EnableAutoCursorLine` / `:DisableAutoCursorLine` | Start / stop switching `cursorline` |
| `:EnableAutoCursorColumn` / `:DisableAutoCursorColumn` | Start / stop switching `cursorcolumn` |

Disabling also clears the option right away. The commands work without calling
`setup()`; only the autocmds need it.

## Lua API

```lua
local autocursor = require("autocursor")
autocursor.enable("cursorline")   -- == :EnableAutoCursorLine
autocursor.disable("cursorcolumn")-- == :DisableAutoCursorColumn
```

## Health

```vim
:checkhealth autocursor
```

## License

MIT
