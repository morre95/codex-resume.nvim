local M = {}

-- Default plugin configuration; values are duplicated via deepcopy to avoid shared tables.
local default_config = {
  cmd = "codex",
  float = {
    border = "rounded",
    width = 0.85,
    height = 0.8,
  },
  auto_close = true,
}

local function deepcopy(value)
  if type(value) ~= "table" then
    return value
  end

  local result = {}
  for k, v in pairs(value) do
    result[k] = deepcopy(v)
  end
  return result
end

local config = deepcopy(default_config)

local function merge_configs(base, override)
  if type(base) ~= "table" then
    return deepcopy(override)
  end

  if type(override) ~= "table" then
    if override == nil then
      return deepcopy(base)
    end
    return deepcopy(override)
  end

  local result = {}

  for k, v in pairs(base) do
    result[k] = deepcopy(v)
  end

  for k, v in pairs(override) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = merge_configs(result[k], v)
    else
      result[k] = deepcopy(v)
    end
  end

  return result
end

local function float_dimensions()
  local columns = vim.o.columns
  local lines = vim.o.lines - vim.o.cmdheight

  local width = config.float.width
  local height = config.float.height

  if width > 0 and width < 1 then
    width = math.floor(columns * width)
  else
    width = math.min(columns, math.floor(width))
  end

  if height > 0 and height < 1 then
    height = math.floor(lines * height)
  else
    height = math.min(lines, math.floor(height))
  end

  local row = math.floor((lines - height) / 2)
  local col = math.floor((columns - width) / 2)

  return width, height, row, col
end

local function close_float(win, buf)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end

  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

local function set_buf_option(buf, name, value)
  local ok, err = pcall(vim.api.nvim_buf_set_option, buf, name, value)
  if not ok then
    vim.notify(
      string.format("codex.nvim: failed to set %s: %s", name, err),
      vim.log.levels.WARN
    )
  end
end

local function open_term(args, opts)
  opts = opts or {}

  local buf = vim.api.nvim_create_buf(false, true)
  local width, height, row, col = float_dimensions()

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = config.float.border,
    width = width,
    height = height,
    row = row,
    col = col,
  })

  set_buf_option(buf, "filetype", "codex_session")
  set_buf_option(buf, "buftype", "terminal")

  local function on_exit(_, code, _)
    if config.auto_close and code == 0 then
      close_float(win, buf)
    elseif not config.auto_close then
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_set_option(win, "cursorline", true)
        end
      end)
    end

    if opts.on_exit then
      opts.on_exit(code)
    end
  end

  local job = vim.fn.termopen(args, {
    cwd = opts.cwd,
    env = opts.env,
    on_exit = on_exit,
  })

  if job <= 0 then
    close_float(win, buf)
    vim.notify(
      "codex.nvim: failed to start `" .. table.concat(args, " ") .. "`",
      vim.log.levels.ERROR
    )
    return
  end

  vim.keymap.set("n", "q", function()
    close_float(win, buf)
  end, { buffer = buf, nowait = true })

  vim.cmd("startinsert")

  return {
    buf = buf,
    win = win,
    job = job,
  }
end

local function run_system(args, opts)
  opts = opts or {}

  if vim.system then
    local task = vim.system(args, { text = true, cwd = opts.cwd, env = opts.env })
    local result = task:wait()

    if result.code ~= 0 then
      vim.notify("codex.nvim: command failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
    elseif result.stdout and #result.stdout > 0 then
      vim.notify(result.stdout, vim.log.levels.INFO)
    end

    return result
  end

  local output = vim.fn.system(args)
  local status = vim.v.shell_error

  if status ~= 0 then
    vim.notify("codex.nvim: command failed: " .. output, vim.log.levels.ERROR)
  elseif output and #output > 0 then
    vim.notify(output, vim.log.levels.INFO)
  end

  return {
    code = status,
    stdout = output,
  }
end

local function build_command(extra)
  local cmd = { config.cmd, "resume" }

  if extra then
    for _, item in ipairs(extra) do
      table.insert(cmd, item)
    end
  end

  return cmd
end

function M.setup(opts)
  config = merge_configs(default_config, opts or {})
end

function M.resume(opts)
  opts = opts or {}

  local args = build_command(opts.args)
  if opts.interactive == false then
    return run_system(args, opts)
  end

  return open_term(args, opts)
end

function M.resume_last(opts)
  opts = opts or {}
  opts.args = { "--last" }

  if opts.interactive == nil then
    opts.interactive = true
  end

  return M.resume(opts)
end

function M.resume_by_id(id, opts)
  if not id or id == "" then
    vim.notify("codex.nvim: resume_by_id requires an id", vim.log.levels.ERROR)
    return
  end

  opts = opts or {}
  opts.args = { id }

  if opts.interactive == nil then
    opts.interactive = true
  end

  return M.resume(opts)
end

function M.get_config()
  return deepcopy(config)
end

return M