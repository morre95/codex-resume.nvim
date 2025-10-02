if vim.g.codex_plugin_loaded then
  return
end
vim.g.codex_plugin_loaded = true

local function with_interactive(flag)
  return flag == 0
end

local function safe_require()
  local ok, mod = pcall(require, "codex")
  if not ok then
    vim.notify("codex.nvim: failed to load core module: " .. mod, vim.log.levels.ERROR)
    return nil
  end
  return mod
end

vim.api.nvim_create_user_command("CodexResume", function(params)
  local mod = safe_require()
  if not mod then
    return
  end

  local interactive = with_interactive(params.bang)
  local arg = params.args

  if arg == "" then
    mod.resume({ interactive = interactive })
    return
  end

  if arg == "--last" or arg == "last" then
    mod.resume_last({ interactive = interactive })
    return
  end

  mod.resume_by_id(arg, { interactive = interactive })
end, {
  nargs = "?",
  bang = true,
  complete = function()
    return { "--last", "last" }
  end,
})

vim.api.nvim_create_user_command("CodexResumeLast", function(params)
  local mod = safe_require()
  if not mod then
    return
  end
  mod.resume_last({ interactive = with_interactive(params.bang) })
end, { nargs = 0, bang = true })

vim.api.nvim_create_user_command("CodexResumeId", function(params)
  local mod = safe_require()
  if not mod then
    return
  end
  mod.resume_by_id(params.args, { interactive = with_interactive(params.bang) })
end, { nargs = 1, bang = true })