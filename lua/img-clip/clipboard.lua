local util = require("img-clip.util")
local config = require("img-clip.config")

local M = {}

M.clip_cmd = nil

---@return string | nil
M.get_clip_cmd = function()
  if M.clip_cmd then
    return M.clip_cmd

  -- Windows
  elseif (util.has("win32") or util.has("wsl")) and util.executable("powershell.exe") then
    M.clip_cmd = "powershell.exe"

  -- MacOS
  elseif util.has("mac") then
    if util.executable("pngpaste") then
      M.clip_cmd = "pngpaste"
    end

  -- Linux (Wayland)
  elseif os.getenv("WAYLAND_DISPLAY") and util.executable("wl-paste") then
    M.clip_cmd = "wl-paste"

  -- Linux (X11)
  elseif os.getenv("DISPLAY") and util.executable("xclip") then
    M.clip_cmd = "xclip"
  else
    return nil
  end

  return M.clip_cmd
end

---@return boolean
M.content_is_image = function()
  local cmd = M.get_clip_cmd()

  -- Linux (X11)
  if cmd == "xclip" then
    local output = util.execute("xclip -selection clipboard -t TARGETS -o")
    return output ~= nil and output:find("image/png") ~= nil

  -- Linux (Wayland)
  elseif cmd == "wl-paste" then
    local output = util.execute("wl-paste --list-types")
    return output ~= nil and output:find("image/png") ~= nil

  -- MacOS (pngpaste)
  elseif cmd == "pngpaste" then
    local _, exit_code = util.execute("pngpaste -")
    return exit_code == 0

  -- Windows
  elseif cmd == "powershell.exe" then
    local output =
      util.execute("Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Clipboard]::GetImage()")
    return output ~= nil and output:find("Width") ~= nil
  end

  return false
end

M.save_image = function(file_path)
  local cmd = M.get_clip_cmd()
  local process_cmd = config.get_opt("process_cmd")
  if process_cmd ~= "" then
    process_cmd = "| " .. process_cmd .. " "
  end

  -- Linux (X11)
  if cmd == "xclip" then
    local command =
      string.format('xclip -selection clipboard -o -t image/png %s> "%s"', process_cmd:gsub("%%", "%%%%"), file_path)
    local _, exit_code = util.execute(command)
    return exit_code == 0

  -- Linux (Wayland)
  elseif cmd == "wl-paste" then
    local command = string.format('wl-paste --type image/png %s> "%s"', process_cmd:gsub("%%", "%%%%"), file_path)
    local _, exit_code = util.execute(command)
    return exit_code == 0

  -- MacOS (pngpaste)
  elseif cmd == "pngpaste" then
    local command = string.format('pngpaste - %s> "%s"', process_cmd:gsub("%%", "%%%%"), file_path)
    local _, exit_code = util.execute(command)
    return exit_code == 0

  -- Windows
  elseif cmd == "powershell.exe" then
    local command = string.format(
      "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Clipboard]::GetImage().Save('%s')",
      file_path
    )
    local _, exit_code = util.execute(command)
    return exit_code == 0
  end

  return false
end

---@return string | nil
M.get_content = function()
  local cmd = M.get_clip_cmd()

  -- Linux (X11)
  if cmd == "xclip" then
    for _, target in ipairs({ "text/plain", "text/uri-list" }) do
      local command = string.format("xclip -selection clipboard -t %s -o", target)
      local output, exit_code = util.execute(command)
      if exit_code == 0 then
        return output:match("^[^\n]+") -- only return first line
      end
    end

  -- Linux (Wayland)
  elseif cmd == "wl-paste" then
    local output, exit_code = util.execute("wl-paste")
    if exit_code == 0 then
      return output:match("^[^\n]+")
    end

  -- MacOS
  elseif cmd == "pngpaste" then
    local output, exit_code = util.execute("pbpaste")
    if exit_code == 0 then
      return output:match("^[^\n]+")
    end

  -- Windows
  elseif cmd == "powershell.exe" then
    local output, exit_code = util.execute([[powershell -command "Get-Clipboard"]])
    if exit_code == 0 then
      return output:match("^[^\n]+")
    end
  end

  return nil
end

M.get_base64_encoded_image = function()
  local cmd = M.get_clip_cmd()
  local process_cmd = config.get_opt("process_cmd")
  if process_cmd ~= "" then
    process_cmd = "| " .. process_cmd .. " "
  end

  -- Linux (X11)
  if cmd == "xclip" then
    local output, exit_code =
      util.execute("xclip -selection clipboard -o -t image/png " .. process_cmd .. "| base64 | tr -d '\n'")
    if exit_code == 0 then
      return output
    end

  -- Linux (Wayland)
  elseif cmd == "wl-paste" then
    local output, exit_code = util.execute("wl-paste --type image/png " .. process_cmd .. "| base64 | tr -d '\n'")
    if exit_code == 0 then
      return output
    end

  -- MacOS (pngpaste)
  elseif cmd == "pngpaste" then
    local output, exit_code = util.execute("pngpaste - " .. process_cmd .. "| base64 | tr -d '\n'")
    if exit_code == 0 then
      return output
    end

  -- Windows
  elseif cmd == "powershell.exe" then
    local output, exit_code = util.execute(
      [[Add-Type -AssemblyName System.Windows.Forms; $ms = New-Object System.IO.MemoryStream;]]
        .. [[ [System.Windows.Forms.Clipboard]::GetImage().Save($ms, [System.Drawing.Imaging.ImageFormat]::Png);]]
        .. [[ [System.Convert]::ToBase64String($ms.ToArray())]]
    )
    if exit_code == 0 then
      return output:gsub("\r\n", ""):gsub("\n", ""):gsub("\r", "")
    end
  end

  return nil
end
return M
