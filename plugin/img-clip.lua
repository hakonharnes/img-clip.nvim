local debug = require("img-clip.debug")
local config = require("img-clip.config")
local util = require("img-clip.util")
local plugin = require("img-clip")

vim.api.nvim_create_user_command("PasteImage", function()
  plugin.pasteImage()
end, {})

vim.api.nvim_create_user_command("ImgClipDebug", function()
  debug.print_log()
end, {})

vim.api.nvim_create_user_command("ImgClipConfig", function()
  config.print_config()
end, {})

local buffer = ""

---@param lines string[]
---@param phase number
local function convert_streaming_paste(lines, phase)
  if phase == 1 then
    buffer = ""
  end

  for i, line in ipairs(lines) do
    buffer = buffer .. line
    if i < #lines then
      buffer = buffer .. "\n"
    end
  end

  if phase == 3 then -- end of the paste
    local complete_lines = vim.split(buffer, "\n")
    vim.paste(complete_lines, -1) -- use -1 to indicate non-streaming paste
  end
end

-- override vim.paste to handle image pasting from system clipboard
-- vim.paste is triggered when the users drops an image or file into the terminal
-- it will contain the path to the image or file, or a link to the image
vim.paste = (function(original)
  return function(lines, phase)
    debug.log("Paste: " .. vim.inspect(lines))

    if config.get_opt("drag_and_drop.enabled") == false then
      return original(lines, phase)
    end

    if config.get_opt("drag_and_drop.insert_mode") == false and vim.fn.mode() == "i" then
      return original(lines, phase)
    end

    if phase ~= -1 then
      return convert_streaming_paste(lines, phase)
    end

    if #lines > 2 or #lines == 0 then
      return original(lines, phase)
    end

    local line = lines[1]

    debug.log("Line: " .. line)

    -- probably not a file path or url to an image if the input is this long
    if string.len(line) > 512 then
      return original(lines, phase)
    end

    -- Only treat the paste as a potential image drop if it actually looks
    -- like an image url or path. Some terminals (e.g. Ghostty) route regular
    -- Cmd+V pastes and IME commits through vim.paste, and those must be
    -- passed through silently instead of warning "Content is not an image".
    if not (util.is_image_url(line) or util.is_image_path(line)) then
      return original(lines, phase)
    end

    util.verbose = false
    config.drag_and_drop = true

    local ok = plugin.pasteImage({}, line)

    config.drag_and_drop = false
    util.verbose = true

    if not ok then
      debug.log("Did not handle paste, calling original vim.paste")
      return original(lines, phase) -- if we did not handle the paste, call the original vim.paste function
    end
  end
end)(vim.paste)
