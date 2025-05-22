local config = require("img-clip.config")
local fs = require("img-clip.fs")
local db = require("img-clip.debug")

local M = {}

---@param template string
---@return string[]
function M.split_lines(template)
  local lines = vim.split(template, "\n")

  if lines[1] and lines[1]:match("^%s*$") then
    table.remove(lines, 1)
  end

  if lines[#lines] and lines[#lines]:match("^%s*$") then
    table.remove(lines)
  end

  return lines
end

---@param cur_row number
---@param lines string[]
---@return number new_row The new cursor row pos
---@return string matched_line The matched line in the tempalte (or the last line if no match)
---@return number matched_line_index The index of the matched line
function M.get_new_cursor_row(cur_row, lines)
  for i, line in ipairs(lines) do
    if line:match("$CURSOR") then
      local new_row = config.get_opt("insert_at_cursor") and (cur_row - 1) or cur_row
      return new_row + i, line, i
    end
  end

  local new_row = config.get_opt("insert_at_cursor") and (cur_row - 1) or cur_row
  return new_row + #lines, lines[#lines], #lines
end

---@param line string
---@param index number The line index of the template where the line param is found
---@param cur_col number The column index on which the cursor is currently positioned
---@return number new_col The new cursor col pos
function M.get_new_cursor_col(line, index, cur_col)
  local cursor_pos = line:find("$CURSOR")
  if cursor_pos then
    if config.get_opt("insert_at_cursor") and index == 1 then
      return cur_col + cursor_pos
    end
    return cursor_pos - 1
  end

  if config.get_opt("insert_at_cursor") and index == 1 then
    return cur_col + string.len(line)
  end

  return string.len(line) - 1
end

---@param str string
---@return string
M.url_encode = function(str)
  if str then
    str = str:gsub("\\", "/")
    str = str:gsub("[ ]", function(c)
      return string.format("%%%02X", string.byte(c))
    end)
  end
  return str
end

---@param input string
---@param is_file_path? boolean
---@return string | nil
function M.get_template(input, is_file_path)
  local template_args = {
    file_path = "",
    file_name = "",
    file_name_no_ext = "",
    cursor = "$CURSOR",
    label = "",
  }

  if is_file_path then
    template_args.file_path = input
    template_args.file_name = vim.fn.fnamemodify(input, ":t")
    template_args.file_name_no_ext = vim.fn.fnamemodify(input, ":t:r")
    template_args.label = template_args.file_name_no_ext:gsub("%s+", "-"):lower()

    -- see issue #21
    local current_dir_path = vim.fn.expand("%:p:h")
    if
      config.get_opt("relative_template_path")
      and not config.get_opt("use_absolute_path")
      and current_dir_path ~= vim.fn.getcwd()
    then
      template_args.file_path = fs.relpath(template_args.file_path, current_dir_path)
    elseif config.get_opt("use_absolute_path") then
      template_args.file_path = vim.fn.fnamemodify(template_args.file_path, ":p")
    end

    -- url encode path
    if config.get_opt("url_encode_path") then
      template_args.file_path = M.url_encode(template_args.file_path)
      template_args.file_path = template_args.file_path:gsub("%%", "%%%%") -- escape % so we can call gsub again
    end
  else
    template_args.file_path = input
  end

  local template = config.get_opt("template", template_args)
  if not template then
    return nil
  end

  template = template:gsub("$FILE_NAME_NO_EXT", template_args.file_name_no_ext)
  template = template:gsub("$FILE_NAME", template_args.file_name)
  template = template:gsub("$FILE_PATH", template_args.file_path)
  template = template:gsub("$LABEL", template_args.label)

  if not config.get_opt("use_cursor_in_template") then
    template = template:gsub("$CURSOR", "")
  end

  return template
end

---@param input string
---@param is_file_path? boolean
---@return boolean
function M.insert_markup(input, is_file_path)
  local template = M.get_template(input, is_file_path)
  if not template then
    return false
  end

  -- get current cursor position
  local lines = M.split_lines(template)
  local cur_pos = vim.api.nvim_win_get_cursor(0)
  local cur_row = cur_pos[1]
  local cur_col = cur_pos[2]

  -- get new cursor position
  local new_row, line, index = M.get_new_cursor_row(cur_row, lines)
  local new_col = M.get_new_cursor_col(line, index, cur_col)

  -- remove cursor placeholder from template
  lines[index] = line:gsub("$CURSOR", "")

  -- paste lines and place cursor in correct position
  local mode = "l"
  if config.get_opt("insert_at_cursor") then
    mode = "c"
  end
  vim.api.nvim_put(lines, mode, true, true)
  vim.api.nvim_win_set_cursor(0, { new_row, new_col })

  -- enter insert mode if configured
  if config.get_opt("insert_mode_after_paste") and vim.api.nvim_get_mode().mode ~= "i" then
    if new_col == string.len(line) - 1 or (index == 1 and config.get_opt("insert_at_cursor")) then
      vim.api.nvim_input("a")
    else
      vim.api.nvim_input("i")
    end
  end

  return true
end

return M
