local utils = {}

utils.get_cell_marker = function(bufnr, cell_markers)
  local ft = vim.bo[bufnr].filetype

  local user_opt_cell_marker = cell_markers[ft]
  if user_opt_cell_marker then
    return user_opt_cell_marker
  end

  -- use double percent markers as default for cell markers
  -- DOCS https://jupytext.readthedocs.io/en/latest/formats-scripts.html#the-percent-format
  if not vim.bo.commentstring then
    error("There's no cell marker and no commentstring defined for filetype " .. ft)
  end
  local cstring = string.gsub(vim.bo.commentstring, "^%%", "%%%%")
  local double_percent_cell_marker = cstring:format "%%"
  return double_percent_cell_marker
end

local find_supported_repls = function()
  local supported_repls = {
    { name = "iron", module = "iron" },
    { name = "toggleterm", module = "toggleterm" },
    { name = "molten", module = "molten.health" },
  }

  local available_repls = {}
  for _, repl in pairs(supported_repls) do
    if pcall(require, repl.module) then
      available_repls[#available_repls + 1] = repl.name
    end
  end

  return available_repls
end

utils.available_repls = find_supported_repls()

utils.has_value = function(tab, val)
  for _, value in ipairs(tab) do
    if value == val then
      return true
    end
  end

  return false
end

return utils
