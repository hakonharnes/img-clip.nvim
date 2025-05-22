local config = require("img-clip.config")
local debug = require("img-clip.debug")
local mime_types = require("img-clip.mime_types")

local M = {}

M.verbose = true

---@param input_cmd string
---@param execute_directly? boolean
---@return string | nil output
---@return number exit_code
M.execute = function(input_cmd, execute_directly)
  local shell = vim.o.shell:lower()
  local cmd

  -- execute command directly if shell is powershell or pwsh or explicitly requested
  if execute_directly or shell:match("powershell") or shell:match("pwsh") then
    cmd = input_cmd

  -- WSL requires the command to have the format:
  -- powershell.exe -Command 'command "path/to/file"'
  elseif M.has("wsl") then
    if input_cmd:match("curl") then
      cmd = input_cmd
    else
      cmd = "powershell.exe -NoProfile -Command '" .. input_cmd:gsub("'", '"') .. "'"
    end

  -- cmd.exe requires the command to have the format:
  -- powershell.exe -Command "command 'path/to/file'"
  elseif M.has("win32") then
    cmd = 'powershell.exe -NoProfile -Command "' .. input_cmd:gsub('"', "'") .. '"'

  -- otherwise (linux, macos), execute the command directly
  else
    cmd = "sh -c " .. vim.fn.shellescape(input_cmd)
  end

  local output = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  debug.log("Shell: " .. shell)
  debug.log("Command: " .. cmd)
  debug.log("Exit code: " .. exit_code)
  debug.log("Output: " .. output)

  return output, exit_code
end

M.executable = function(command)
  return vim.fn.executable(command) == 1
end

---@param feature string
M.has = function(feature)
  return vim.fn.has(feature) == 1
end

---@param msg string
---@param verbose boolean?
M.warn = function(msg, verbose)
  if M.verbose or verbose then
    vim.notify(msg, vim.log.levels.WARN, { title = "img-clip" })
  end
end

---@param msg string
---@param verbose boolean?
M.error = function(msg, verbose)
  if M.verbose or verbose then
    vim.notify(msg, vim.log.levels.ERROR, { title = "img-clip" })
  end
end

---@param msg string
M.debug = function(msg)
  if config.options.debug then
    vim.notify(msg, vim.log.levels.DEBUG, { title = "img-clip" })
  end
end

---@param args table
M.input = function(args)
  local completed, output = pcall(function()
    return vim.fn.input(args)
  end)

  if not completed then
    return nil
  end

  return output
end

---@param str string
---@return string
M.sanitize_input = function(str)
  str = str:match("^%s*(.-)%s*$") -- remove leading and trailing whitespace
  str = str:match('^"?(.-)"?$') -- remove double quotes
  str = str:match("^'?(.-)'?$") -- remove single quotes
  str = str:gsub("file://", "") -- remove "file://"
  str = str:gsub("%c", "") -- remove control characters

  return str
end

---@param str string
---@return boolean
M.is_image_url = function(str)
  -- return early if not a valid url to a subdomain
  if not str:match("^https?://[^/]+/[^.]+") then
    return false
  end

  -- assume its a valid image link if it the url ends with an extension
  local extension = str:match("%.(%w+)$") -- Assumes that the extensions are alphanumeric

  local image_formats = config.get_opt("formats")

  if extension ~= nil then
    --- @cast image_formats table
    for _, ext in ipairs(image_formats) do
      if extension == ext then
        return true
      end
    end

    -- This format was not supported in the user's config
    return false
  end

  -- send a head request to the url and check content type.
  -- Add the 'CONTENT_TYPE' text on the last line for easier matching
  local command = string.format("curl -s -I -w 'CONTENT_TYPE: %%{content_type}' '%s'", str)

  local output, exit_code = M.execute(command)

  if exit_code ~= 0 or output == nil then
    return false
  end

  -- Match the content type
  -- The capture group is any pattern, until the next semi-colon or white space.
  -- Note this makes the assumption that the actual content type is first
  ---@cast output string
  local content_type = string.match(output, "CONTENT_TYPE:%s([^%s;]+)")

  --- @cast image_formats table
  return content_type ~= nil and mime_types.is_supported_mime_type(content_type, image_formats)
end

---@param str string
---@return boolean
M.is_image_path = function(str)
  str = string.lower(str)

  local has_path_sep = str:find("/") ~= nil or str:find("\\") ~= nil

  local extension = str:match("%.(%w+)$") -- Assumes that the extensions are alphanumeric

  if extension == nil then
    return false
  end

  local formats = config.get_opt("formats")

  local has_supported_format = false
  --- @cast formats table
  for _, ext in ipairs(formats) do
    has_supported_format = has_supported_format or (ext == extension)
    if has_supported_format then
      break
    end
  end

  return has_path_sep and has_supported_format
end

return M
