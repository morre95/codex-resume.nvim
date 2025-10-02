# Codex Resume.nvim

A lightweight Neovim companion for the [OpenAI Codex CLI](https://github.com/openai/codex). Launch the `codex resume` picker, attach to the most recent session, or resume any session by id without leaving Neovim.

## Requirements
- Neovim 0.8.0 or newer (0.10 recommended for `vim.system` support)
- OpenAI Codex CLI installed and available on your `$PATH`

## Installation

### lazy.nvim
```lua
{
  "morre95/codex-resume.nvim",
  cmd = { "CodexResume", "CodexResumeLast", "CodexResumeId" },
  keys = {
    { "<leader>cr", function() require("codex").resume() end, desc = "Codex: resume session" },
    { "<leader>cR", function() require("codex").resume_last() end, desc = "Codex: resume last" },
  },
  opts = {
    auto_close = true,
    float = {
      border = "single",
      width = 0.9,
      height = 0.85,
    },
  },
}
```

### packer.nvim
```lua
use {
  "morre95/codex-resume.nvim",
  config = function()
    require("codex").setup()
  end,
}
```

## Usage
- `:CodexResume` - open the Codex CLI session picker inside a floating terminal.
- `:CodexResume --last` - resume the most recent session.
- `:CodexResume <session-id>` - resume a specific session.
- `:CodexResume! ...` - run any variant above without a floating terminal (uses `vim.system` / `vim.fn.system`).
- `:CodexResumeLast` and `:CodexResumeId <id>` - convenience aliases for scripted use.

The floating terminal closes automatically when the resume command exits successfully. Set `auto_close = false` if you need to inspect the CLI output afterwards.

## Configuration
```lua
require("codex").setup {
  cmd = "codex",             -- override when the CLI binary lives elsewhere
  auto_close = true,          -- close the floating window after a successful run
  float = {
    border = "rounded",      -- any `nvim_open_win` border value
    width = 0.85,             -- fraction of the editor width or absolute columns
    height = 0.8,             -- fraction of the editor height or absolute rows
  },
}
```

With `:CodexResume!` (or by setting `interactive = false` when calling from Lua) the plugin shells out and surfaces the CLI output using `vim.notify`.

## Lua API
```lua
local codex = require("codex")

codex.resume(opts)             -- main entry point
codex.resume_last(opts)
codex.resume_by_id("session-uuid", opts)

-- Example: resume the last session without opening a terminal window
codex.resume_last({ interactive = false })
```

`opts.interactive` controls whether the command runs in a floating terminal (`true`, default) or via `vim.system` / `vim.fn.system` (`false`). Additional arguments can be forwarded with `opts.args` when calling `codex.resume` directly.
