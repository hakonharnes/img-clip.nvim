local clipboard = require("img-clip.clipboard")
local paste = require("img-clip.paste")
local plugin = require("img-clip")
local config = require("img-clip.config")
local util = require("img-clip.util")
local spy = require("luassert.spy")

describe("paste", function()
  before_each(function()
    config.setup({})
    config.get_config = function()
      return config.opts
    end
    os.getenv = function(env)
      return env == "DISPLAY"
    end
    util.has = function()
      return false
    end
    util.executable = function(cmd)
      return cmd == "xclip"
    end
  end)

  describe("paste_image", function()
    it("should paste image from clipboard if clipboard content is image", function()
      clipboard.content_is_image = function()
        return true
      end

      paste.paste_image_from_clipboard = function()
        return true
      end

      spy.on(paste, "paste_image_from_clipboard")

      paste.paste_image()
      assert.spy(paste.paste_image_from_clipboard).was_called()
    end)

    it("should paste image from input if given explicitly", function()
      paste.paste_image_from_path = function()
        return true
      end

      spy.on(paste, "paste_image_from_path")

      plugin.paste_image({}, "/home/user/Pictures/image.png")
      assert.spy(paste.paste_image_from_path).was_called()

      paste.paste_image_from_url = function()
        return true
      end

      spy.on(paste, "paste_image_from_url")

      plugin.paste_image({}, "https://example.com/image.png")
      assert.spy(paste.paste_image_from_url).was_called()
    end)

    it("should paste image from clipboard if clipboard content is a file path or url", function()
      clipboard.content_is_image = function()
        return false
      end

      clipboard.get_content = function()
        return "/home/user/Pictures/image.png"
      end

      paste.paste_image_from_path = function()
        return true
      end

      spy.on(paste, "paste_image_from_path")

      paste.paste_image()
      assert.spy(paste.paste_image_from_path).was_called()

      clipboard.get_content = function()
        return "https://example.com/image.png"
      end

      paste.paste_image_from_url = function()
        return true
      end

      spy.on(paste, "paste_image_from_url")

      paste.paste_image()
      assert.spy(paste.paste_image_from_url).was_called()
    end)
  end)
end)

describe("vim.paste wrapper", function()
  local original_calls
  local notifications
  local orig_notify
  local wrapper_installed_here

  -- The test harness runs nvim with --noplugin, so the plugin file that
  -- installs the vim.paste wrapper is never sourced. Point vim.paste at a
  -- recorder and source the plugin file so the wrapper wraps the recorder;
  -- the tests then assert on the recorder and on captured notifications.
  do
    local cmds = vim.api.nvim_get_commands({})
    if not cmds["PasteImage"] then
      original_calls = {}
      vim.paste = function(lines, phase)
        table.insert(original_calls, { lines = lines, phase = phase })
      end
      local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
      local ok, err = pcall(dofile, root .. "/plugin/img-clip.lua")
      assert(ok, "could not source plugin/img-clip.lua: " .. tostring(err))
      wrapper_installed_here = true
    end
  end

  before_each(function()
    config.setup({
      default = {
        drag_and_drop = {
          enabled = true,
          insert_mode = true,
        },
      },
    })
    config.get_config = function()
      return config.opts
    end
    config.api_opts = {}
    config.drag_and_drop = false
    util.verbose = true

    if original_calls then
      original_calls = {}
    end

    notifications = {}
    orig_notify = vim.notify
    vim.notify = function(msg, level, opts)
      table.insert(notifications, { msg = msg, level = level, opts = opts })
    end
  end)

  after_each(function()
    vim.notify = orig_notify
  end)

  local function warned(msg)
    for _, n in ipairs(notifications) do
      if n.msg == msg then
        return true
      end
    end
    return false
  end

  it("passes regular text pastes through without warning", function()
    vim.paste({ "hello world" }, -1)

    if wrapper_installed_here then
      assert.are.equal(1, #original_calls, "original vim.paste should be called for non-image pastes")
      assert.are.same({ "hello world" }, original_calls[1].lines)
    end
    assert.is_falsy(warned("Content is not an image."))
  end)

  it("still handles image path pastes", function()
    paste.paste_image_from_path = function()
      return true
    end
    spy.on(paste, "paste_image_from_path")

    vim.paste({ "/home/user/Pictures/image.png" }, -1)

    assert.spy(paste.paste_image_from_path).was_called()
    assert.is_falsy(warned("Content is not an image."))
    if wrapper_installed_here then
      assert.are.equal(0, #original_calls, "original vim.paste should not be called for image pastes")
    end
  end)
end)
