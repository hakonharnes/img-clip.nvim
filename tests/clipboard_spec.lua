local clipboard = require("img-clip.clipboard")
local config = require("img-clip.config")
local util = require("img-clip.util")

describe("clipboard", function()
  before_each(function()
    config.setup({})
    clipboard.clip_cmd = nil
    config.get_config = function()
      return config.opts
    end
  end)

  -- incompatible os
  describe("Incompatible", function()
    before_each(function()
      os.getenv = function()
        return false
      end
      util.has = function()
        return false
      end
      util.executable = function()
        return false
      end
    end)

    it("return nil if clipboard command cant be found", function()
      assert.equals(nil, clipboard.get_clip_cmd())
    end)
  end)

  -- X11
  describe("x11", function()
    before_each(function()
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

    it("returns 'xclip' as the clipboard command", function()
      assert.equals("xclip", clipboard.get_clip_cmd())
    end)

    it("returns true if clipboard content is an image", function()
      util.execute = function(command)
        assert(command:match("xclip"))
        return [[TARGETS\nimage/png]], 0 -- output of xclip
      end

      assert.is_true(clipboard.content_is_image())
    end)

    it("returns false if clipboard content is not an image", function()
      util.execute = function(command)
        assert(command:match("xclip"))
        return [[TARGETS\nUTF8_STRING]], 0 -- output of xclip
      end

      assert.is_false(clipboard.content_is_image())
    end)

    it("gets first line of clipboard content", function()
      util.execute = function(command)
        assert(command:match("xclip"))
        return [[first line
        second line]], 0
      end

      assert.equals("first line", clipboard.get_content())
    end)

    it("successfully saves an image", function()
      util.execute = function(command)
        assert(command:match("xclip"))
        return nil, 0 -- simulate successful execution
      end

      assert.is_true(clipboard.save_image("xclip", "/path/to/image.png"))
    end)
  end)

  -- Wayland
  describe("wayland", function()
    before_each(function()
      os.getenv = function(env)
        return env == "WAYLAND_DISPLAY" or env == "DISPLAY"
      end
      util.has = function()
        return false
      end
      util.executable = function(cmd)
        return cmd == "wl-paste" or cmd == "wl-clipboard"
      end
    end)

    it("returns 'wl-paste' as the clipboard command", function()
      assert.equals("wl-paste", clipboard.get_clip_cmd())
    end)

    it("returns true if clipboard content is an image", function()
      util.execute = function(command)
        assert(command:match("wl%-paste"))
        return [[TARGETS\nimage/png]], 0 -- output of wl-paste
      end

      assert.is_true(clipboard.content_is_image())
    end)

    it("returns false if clipboard content is not an image", function()
      util.execute = function(command)
        assert(command:match("wl%-paste"))
        return [[TARGETS\nUTF8_STRING]], 0 -- output of wl-paste
      end

      assert.is_false(clipboard.content_is_image())
    end)

    it("gets first line of clipboard content", function()
      util.execute = function(command)
        assert(command:match("wl%-paste"))
        return [[first line
        second line]], 0
      end

      assert.equals("first line", clipboard.get_content())
    end)

    it("successfully saves an image", function()
      util.execute = function(command)
        assert(command:match("wl%-paste"))
        return nil, 0 -- simulate successful execution
      end

      assert.is_true(clipboard.save_image("/path/to/image.png"))
    end)
  end)

  -- MacOS
  describe("macos", function()
    describe("pngpaste", function()
      before_each(function()
        util.has = function(feature)
          return feature == "mac"
        end
        os.getenv = function()
          return nil
        end
        util.executable = function(cmd)
          return cmd == "pngpaste" 
        end
      end)

      it("returns 'pngpaste' as the clipboard command", function()
        assert.equals("pngpaste", clipboard.get_clip_cmd())
      end)

      it("returns true if clipboard content is an image", function()
        util.execute = function(command)
          assert(command:match("pngpaste"))
          return nil, 0 -- output of pngpaste
        end

        assert.is_true(clipboard.content_is_image())
      end)

      it("returns false if clipboard content is not an image", function()
        util.execute = function(command)
          assert(command:match("pngpaste"))
          return nil, 1 -- output of pngpaste
        end

        assert.is_false(clipboard.content_is_image())
      end)

      it("gets first line of clipboard content", function()
        util.execute = function(command)
          assert(command:match("pbpaste"))
          return [[first line
        second line]], 0
        end

        assert.equals("first line", clipboard.get_content())
      end)

      it("successfully saves an image", function()
        util.execute = function(command)
          assert(command:match("pngpaste"))
          return nil, 0 -- simulate successful execution
        end

        assert.is_true(clipboard.save_image("/path/to/image.png"))
      end)
    end)
  end)

  -- Windows (including WSL)
  describe("windows", function()
    before_each(function()
      util.has = function(feature)
        return feature == "win32" or feature == "wsl"
      end
      util.executable = function(cmd)
        return cmd == "powershell.exe"
      end
    end)

    it("returns 'powershell.exe' as the clipboard command", function()
      assert.equals("powershell.exe", clipboard.get_clip_cmd())
    end)

    it("returns true if clipboard content is an image", function()
      -- pwsh output, see issue https://github.com/HakonHarnes/img-clip.nvim/issues/13
      util.execute = function()
        return [[
�[32;1mTag                  : �[0m
�[32;1mPhysicalDimension    : �[0m{Width=93, Height=189}
�[32;1mSize                 : �[0m{Width=93, Height=189}
�[32;1mWidth                : �[0m93
�[32;1mHeight               : �[0m189
�[32;1mHorizontalResolution : �[0m96
�[32;1mVerticalResolution   : �[0m96
�[32;1mFlags                : �[0m335888
�[32;1mRawFormat            : �[0mMemoryBMP
�[32;1mPixelFormat          : �[0mFormat32bppRgb
�[32;1mPropertyIdList       : �[0m{}
�[32;1mPropertyItems        : �[0m{}
�[32;1mPalette              : �[0mSystem.Drawing.Imaging.ColorPalette
�[32;1mFrameDimensionsList  : �[0m{7462dc86-6180-4c7e-8e3f-ee7333a7a483}
]],
          0
      end

      assert.is_true(clipboard.content_is_image())
    end)

    it("returns false if clipboard content is not an image", function()
      util.execute = function()
        return "", 0 -- output of powershell
      end

      assert.is_false(clipboard.content_is_image())
    end)

    it("gets first line of clipboard content", function()
      util.execute = function(command)
        assert(command:match("powershell"))
        return [[first line
        second line]], 0
      end

      assert.equals("first line", clipboard.get_content())
    end)

    it("successfully saves an image", function()
      util.execute = function()
        return nil, 0 -- simulate successful execution
      end

      assert.is_true(clipboard.save_image("C:\\path\\to\\image.png"))
    end)
  end)
end)
