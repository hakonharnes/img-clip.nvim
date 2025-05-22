local clipboard = require("img-clip.clipboard")
local markup = require("img-clip.markup")
local config = require("img-clip.config")
local debug = require("img-clip.debug")
local util = require("img-clip.util")
local fs = require("img-clip.fs")

local M = {}

---@param input? string file path or url
---@return boolean
M.paste_image = function(input)
  -- check if input (file path or url) is provided
  if input then
    input = util.sanitize_input(input)

    if util.is_image_url(input) then
      return M.paste_image_from_url(input)
    elseif util.is_image_path(input) then
      return M.paste_image_from_path(input)
    end

    util.warn("Content is not an image.")
    return false
  end

  -- ensure clipboard command is valid
  if not clipboard.get_clip_cmd() then
    util.error("Could not get clipboard command. See :checkhealth img-clip.")
    return false
  end

  -- if no input is provided, check clipboard content
  if clipboard.content_is_image() then
    return M.paste_image_from_clipboard()
  end

  -- if clipboard does not contain an image, then get the
  -- clipboard content as text and check attempt to paste it
  local clipboard_content = clipboard.get_content()
  if clipboard_content then
    return M.paste_image(clipboard_content)
  end

  util.warn("Content is not an image.")
  return false
end

---@param url string
M.paste_image_from_url = function(url)
  -- if we are not downloading images, then just insert the url
  if not config.get_opt("download_images") then
    if not markup.insert_markup(url) then
      util.error("Could not insert markup code.")
      return false
    end

    return true
  end

  local extension = config.get_opt("extension")
  local file_path = fs.get_file_path(extension)
  if not file_path then
    util.error("Could not determine file path.")
    return false
  end

  local dir_path = vim.fn.fnamemodify(file_path, ":h")
  if not fs.mkdirp(dir_path) then
    util.error("Could not create directories.")
    return false
  end

  local _, exit_code = util.execute(string.format("curl -o '%s' '%s'", file_path, url))
  if exit_code ~= 0 then
    util.error("Could not download image.")
    return false
  end

  if config.get_opt("embed_image_as_base64") then
    if M.embed_image_as_base64(file_path) then
      return true
    end
  end

  local output, process_exit_code = fs.process_image(file_path)
  if process_exit_code ~= 0 then
    util.warn("Could not process image.", true)
    util.warn("Output: " .. output, true)
  end

  if not markup.insert_markup(file_path, true) then
    util.error("Could not insert markup code.")
    return false
  end

  return true
end

---@param src_path string
M.paste_image_from_path = function(src_path)
  if config.get_opt("embed_image_as_base64") then
    if M.embed_image_as_base64(src_path) then
      return true
    end
  end

  -- if we are not copying images, then just insert the original path
  if not config.get_opt("copy_images") then
    if not config.get_opt("use_absolute_path") then
      src_path = fs.relpath(src_path)
    end

    if not markup.insert_markup(src_path, true) then
      util.error("Could not insert markup code.")
      return false
    end

    return true
  end

  local extension = vim.fn.fnamemodify(src_path, ":e")
  if extension == "" then
    extension = config.get_opt("extension")
    util.warn(string.format("No extension detected. Using default: %s.", extension))
  end

  local file_path = fs.get_file_path(extension)
  if not file_path then
    util.error("Could not determine file path.")
    return false
  end

  local dir_path = vim.fn.fnamemodify(file_path, ":h")
  if not fs.mkdirp(dir_path) then
    util.error("Could not create directories.")
    return false
  end

  if not fs.copy_file(src_path, file_path) then
    util.error("Could not copy image.")
    return false
  end

  local output, exit_code = fs.process_image(file_path)
  if exit_code ~= 0 then
    util.warn("Could not process image.", true)
    util.warn("Output: " .. output, true)
  end

  if not markup.insert_markup(file_path, true) then
    util.error("Could not insert markup code.")
    return false
  end

  return true
end

M.paste_image_from_clipboard = function()
  if config.get_opt("embed_image_as_base64") then
    if M.embed_image_as_base64() then
      return true
    end
  end

  local extension = config.get_opt("extension")
  local file_path = fs.get_file_path(extension)
  if not file_path then
    return false
  end

  local dir_path = vim.fn.fnamemodify(file_path, ":h")
  if not fs.mkdirp(dir_path) then
    util.error("Could not create directories.")
    return false
  end

  if not clipboard.save_image(file_path) then
    util.error("Could not save image to disk.")
    return false
  end

  if util.has("wsl") then
    local output, exit_code = fs.process_image(file_path)
    if exit_code ~= 0 then
      util.warn("Could not process image.", true)
      util.warn("Output: " .. output, true)
    end
  end

  if not markup.insert_markup(file_path, true) then
    util.error("Could not insert markup code.")
    return false
  end

  return true
end

---@param file_path? string
M.embed_image_as_base64 = function(file_path)
  local ft = vim.bo.filetype
  if not M.lang_supports_base64(ft) then
    util.warn("Filetype " .. ft .. " does not support base64 encoding.")
    return false
  end

  local base64
  if file_path then
    base64 = fs.get_base64_encoded_image(file_path)
  else
    base64 = clipboard.get_base64_encoded_image()
  end

  if not base64 then
    util.error("Could not get base64 string.")
    return false
  end

  -- check if base64 string is too long (max_base64_size is in KB)
  local base64_size_kb = math.floor((string.len(base64) * 6) / (8 * 1024))
  local max_size_kb = config.get_opt("max_base64_size")
  debug.log("Base64 size: " .. base64_size_kb .. " KB")
  if base64_size_kb > max_size_kb then
    util.warn("Base64 string is too large (" .. base64_size_kb .. " KB). Max allowed size is " .. max_size_kb .. " KB.")
    return false
  end

  local prefix = M.get_base64_prefix()
  if not markup.insert_markup(prefix .. base64) then
    util.error("Could not insert markup code.")
    return false
  end

  return true
end

---@param ft string
M.lang_supports_base64 = function(ft)
  return ft == "markdown" or ft == "md" or ft == "rmd" or ft == "wiki" or ft == "vimwiki"
end

---@return string
M.get_base64_prefix = function()
  return "data:image/png;base64,"
end

return M
