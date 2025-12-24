local repls = {}

local utils = require "notebook-navigator.utils"

-- iron.nvim
---@diagnostic disable-next-line: unused-local
repls.iron = function(start_line, end_line, repl_args, _cell_marker)
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  require("iron.core").send(nil, lines)

  return true
end

-- toggleterm
---@diagnostic disable-next-line: unused-local
repls.toggleterm = function(start_line, end_line, repl_args, cell_marker)
  local id = 1
  local trim_spaces = false
  local use_bracketed_paste = false
  if repl_args then
    id = repl_args.id or 1
    trim_spaces = (repl_args.trim_spaces == nil) or repl_args.trim_spaces
    use_bracketed_paste = (repl_args.use_bracketed_paste == nil) or repl_args.use_bracketed_paste
  end
  local current_window = vim.api.nvim_get_current_win()
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  if not lines or not next(lines) then
    return
  end

  -- NOTE: Requires https://github.com/akinsho/toggleterm.nvim/pull/591
  if use_bracketed_paste then
    if trim_spaces then
      for i, line in ipairs(lines) do
        lines[i] = line:gsub("^%s+", ""):gsub("%s+$", "")
      end
    end
    local lines_str = table.concat(lines, "\n")
    require("toggleterm").exec(lines_str, id, nil, nil, nil, nil, nil, nil, use_bracketed_paste)
  else
    for _, line in ipairs(lines) do
      local l = trim_spaces and line:gsub("^%s+", ""):gsub("%s+$", "") or line
      require("toggleterm").exec(l, id, nil, nil, nil, nil, nil, nil, use_bracketed_paste)
    end
  end

  -- Jump back with the cursor where we were at the beginning of the selection
  local cursor_line, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_set_current_win(current_window)

  vim.api.nvim_win_set_cursor(current_window, { cursor_line, cursor_col })

  return true
end

-- molten
---@diagnostic disable-next-line: unused-local
repls.molten = function(start_line, end_line, repl_args, cell_marker)
  local line_count = vim.api.nvim_buf_line_count(0)

  -- If we're at the end of the file, we need to add a newline for molten to run everything
  local added_line = false
  if line_count < (end_line + 1) then
    added_line = true
    vim.api.nvim_buf_set_lines(0, end_line + 1, end_line + 1, false, { "" })
  end

  -- Molten will evaluate the given lines, and prompt for a kernel if MoltenInit has not been run
  vim.fn.MoltenEvaluateRange(start_line, end_line + 1)
  if added_line then
    -- If we had added a line we try to remove it.
    -- This works most of the time, but not when MoltenEvaluateRange prompts for a kernel...
    -- I could not find a way to make both work so this seems like a good compromise
    vim.schedule(function()
      vim.api.nvim_buf_set_lines(0, end_line, end_line + 2, false, {})
    end)
  end
  return true
end

-- no repl
repls.no_repl = function(_) end

local get_repl = function(repl_provider)
  local available_repls = utils.available_repls
  if type(repl_provider) ~= "function" and #available_repls == 0 then
    vim.notify "[NotebookNavigator] No supported REPLs available.\nMost functionality will error out."
    return nil
  end

  local chosen_repl = nil
  if repl_provider == "auto" then
    for _, r in ipairs(available_repls) do
      chosen_repl = repls[r]
      break
    end
  elseif type(repl_provider) == "string" then
    chosen_repl = repls[repl_provider]
  elseif type(repl_provider) == "function" then
    chosen_repl = repl_provider
  end

  -- Check if we actually got out a supported repl
  if chosen_repl == nil then
    vim.notify("[NotebookNavigator] The provided repl, " .. repl_provider .. ", is not supported.")
    chosen_repl = repls["no_repl"]
  end

  return chosen_repl
end

return get_repl
