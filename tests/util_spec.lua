local util = require("img-clip.util")
local config = require("img-clip.config")

describe("util", function()
  before_each(function()
    config.setup({})
    config.get_config = function()
      return config.opts
    end
  end)

  describe("execute", function()
    before_each(function()
      vim.o.shell = "cmd.exe"
      vim.fn.system = function(cmd)
        return cmd
      end

      vim.fn.has = function()
        return 0
      end
    end)

    it("should return output and exit code", function()
      local command = "command"
      local output, exit_code = util.execute(command)

      assert.equal(output, "sh -c 'command'")
      assert.equal(exit_code, 0)
    end)

    it("should execute .NET commands directly if shell is powershell", function()
      vim.o.shell = "powershell"

      local command = "command"
      local output, exit_code = util.execute(command)

      assert.equal(command, output)
      assert.equal(exit_code, 0)
    end)

    it("should execute .NET commands directly if shell is pwsh", function()
      vim.o.shell = "pwsh"

      local command = "command"
      local output, exit_code = util.execute(command)

      assert.equal(command, output)
      assert.equal(exit_code, 0)
    end)

    it("should wrap the command in powershell.exe -Command if shell is cmd.exe", function()
      vim.o.shell = "cmd.exe"
      util.has = function(arg)
        return arg == "win32"
      end
      local command = 'command "path/to/file"'
      local output, exit_code = util.execute(command)

      assert.equal([[powershell.exe -NoProfile -Command "command 'path/to/file'"]], output)
      assert.equal(exit_code, 0)
    end)

    it("should wrap the command in powershell.exe -Command if in WSL", function()
      util.has = function(arg)
        return arg == "wsl"
      end

      local command = "command 'path/to/file'"
      local output, exit_code = util.execute(command)

      assert.equal([[powershell.exe -NoProfile -Command 'command "path/to/file"']], output)
      assert.equal(exit_code, 0)
    end)
  end)

  describe("is_image_path", function()
    it("should return true for a valid image path", function()
      assert.is_true(util.is_image_path("/path/to/image.png"))
    end)

    it("should return true for an uppercase image path", function()
      assert.is_true(util.is_image_path("/PATH/TO/IMAGE.JPG"))
    end)

    it("should return false for a non-image file path", function()
      assert.is_false(util.is_image_path("/path/to/file.txt"))
    end)

    it("should return false for a string without a path separator", function()
      assert.is_false(util.is_image_path("image.png"))
    end)

    it("should return false for a string with a path separator but no file extension", function()
      assert.is_false(util.is_image_path("/path/to/image"))
    end)

    it("should return false for a string with an image file extension but no path separator", function()
      assert.is_false(util.is_image_path("image.jpeg"))
    end)
  end)

  describe("is_image_url", function()
    it("should return true for a valid image URL with an extension", function()
      assert.is_true(util.is_image_url("http://example.com/image.png"))
    end)

    it("should return false for a non-image URL", function()
      assert.is_false(util.is_image_url("http://example.com/file.txt"))
    end)

    it("should return false for an invalid URL format", function()
      assert.is_false(util.is_image_url("not_a_valid_url"))
    end)

    it("should return true for a valid image URL without an extension but with image content type", function()
      util.execute = function()
        return "CONTENT_TYPE: image/png", 0
      end
      assert.is_true(util.is_image_url("http://example.com/image"))
    end)

    it("should return false for a URL with non-image content type", function()
      util.execute = function()
        return "text/html", 0
      end
      assert.is_false(util.is_image_url("http://example.com"))
    end)
  end)
end)
