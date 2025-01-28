# 📋 img-clip.nvim

Effortlessly embed images into any markup language, like LaTeX, Markdown or Typst.

https://github.com/HakonHarnes/img-clip.nvim/assets/89907156/ab4edc10-d296-4532-bfce-6abdd4f218bf

## ⚡ Features

- 📋 Paste images directly from your system clipboard
- 🖱️ Seamlessly drag and drop images from your web browser or file explorer
- 📁 Embed images as files, web URLs, or Base64-encoded data
- 🌐 Automatically download and embed images from the web
- ⚙️ Process images using configurable shell commands
- 🎨 Configurable templates with placeholders for file paths, labels, and cursor positioning
- 📝 Built-in templates for popular markup languages like LaTeX, Markdown, and Typst
- 🔧 Extensive configuration options, including per-project, per-directory, and per-filetype settings
- 🔌 Powerful API with example integrations for popular plugins like [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) and [oil.nvim](https://github.com/stevearc/oil.nvim)
- 💻 Compatible with Linux, macOS, and Windows, including WSL!

## 🔧 Requirements

- **Linux:** [xclip](https://github.com/astrand/xclip) (x11) or [wl-clipboard](https://github.com/bugaevc/wl-clipboard) (wayland)
- **MacOS:** [pngpaste](https://github.com/jcsalterego/pngpaste) (optional, but recommended)
- **Windows:** No additional requirements

> [!IMPORTANT]
> Run `:checkhealth img-clip` after installation to ensure requirements are satisfied.

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  opts = {
    -- add options here
    -- or leave it empty to use the default settings
  },
  keys = {
    -- suggested keymap
    { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
  },
}
```

## 🚀 Usage

### Commands

The plugin comes with the following commands:

- `PasteImage`: Pastes an image from the system clipboard
- `ImgClipDebug`: Prints the debug log, including the output of shell commands
- `ImgClipConfig`: Prints the current configuration

> [!TIP]
> Consider binding `PasteImage` to something like `<leader>p`.

### API

You can also use the Lua equivalent, which allows you to override your configuration by passing the options directly to the function:

```lua
require("img-clip").paste_image(opts?, input?) -- input is optional and can be a file path or URL
```

<details> <summary>Example</summary>

```lua
require("img-clip").paste_image({ use_absolute_path = false, file_name = "image.png" }, "/path/to/file.png")
```

</details>

## ⚙️ Configuration

### Setup

The plugin is highly configurable. Please refer to the default configuration below:

```lua
{
  default = {
    -- file and directory options
    dir_path = "assets", ---@type string | fun(): string
    extension = "png", ---@type string | fun(): string
    file_name = "%Y-%m-%d-%H-%M-%S", ---@type string | fun(): string
    use_absolute_path = false, ---@type boolean | fun(): boolean
    relative_to_current_file = false, ---@type boolean | fun(): boolean

    -- template options
    template = "$FILE_PATH", ---@type string | fun(context: table): string
    url_encode_path = false, ---@type boolean | fun(): boolean
    relative_template_path = true, ---@type boolean | fun(): boolean
    use_cursor_in_template = true, ---@type boolean | fun(): boolean
    insert_mode_after_paste = true, ---@type boolean | fun(): boolean

    -- prompt options
    prompt_for_file_name = true, ---@type boolean | fun(): boolean
    show_dir_path_in_prompt = false, ---@type boolean | fun(): boolean

    -- base64 options
    max_base64_size = 10, ---@type number | fun(): number
    embed_image_as_base64 = false, ---@type boolean | fun(): boolean

    -- image options
    process_cmd = "", ---@type string | fun(): string
    copy_images = false, ---@type boolean | fun(): boolean
    download_images = true, ---@type boolean | fun(): boolean
    extra_image_types = {}, ---@type string[]

    -- drag and drop options
    drag_and_drop = {
      enabled = true, ---@type boolean | fun(): boolean
      insert_mode = false, ---@type boolean | fun(): boolean
    },
  },

  -- filetype specific options
  filetypes = {
    markdown = {
      url_encode_path = true, ---@type boolean | fun(): boolean
      template = "![$CURSOR]($FILE_PATH)", ---@type string | fun(context: table): string
      download_images = false, ---@type boolean | fun(): boolean
    },

    vimwiki = {
      url_encode_path = true, ---@type boolean | fun(): boolean
      template = "![$CURSOR]($FILE_PATH)", ---@type string | fun(context: table): string
      download_images = false, ---@type boolean | fun(): boolean
    },

    html = {
      template = '<img src="$FILE_PATH" alt="$CURSOR">', ---@type string | fun(context: table): string
    },

    tex = {
      relative_template_path = false, ---@type boolean | fun(): boolean
      template = [[
\begin{figure}[h]
  \centering
  \includegraphics[width=0.8\textwidth]{$FILE_PATH}
  \caption{$CURSOR}
  \label{fig:$LABEL}
\end{figure}
    ]], ---@type string | fun(context: table): string
    },

    typst = {
      template = [[
#figure(
  image("$FILE_PATH", width: 80%),
  caption: [$CURSOR],
) <fig-$LABEL>
    ]], ---@type string | fun(context: table): string
    },

    rst = {
      template = [[
.. image:: $FILE_PATH
   :alt: $CURSOR
   :width: 80%
    ]], ---@type string | fun(context: table): string
    },

    asciidoc = {
      template = 'image::$FILE_PATH[width=80%, alt="$CURSOR"]', ---@type string | fun(context: table): string
    },

    org = {
      template = [=[
#+BEGIN_FIGURE
[[file:$FILE_PATH]]
#+CAPTION: $CURSOR
#+NAME: fig:$LABEL
#+END_FIGURE
    ]=], ---@type string | fun(context: table): string
    },
  },

  -- file, directory, and custom triggered options
  files = {}, ---@type table | fun(): table
  dirs = {}, ---@type table | fun(): table
  custom = {}, ---@type table | fun(): table
}
```

### Options

Option values can be configured as either static values (e.g. "assets"), or by dynamically generating them through functions.

<details> <summary>Example: Dynamically set the dir path</summary>

To set the `dir_path` to match the name of the currently opened file:

```lua
dir_path = function()
  return vim.fn.expand("%:t:r")
end,
```

</details>

### Processing images

The `process_cmd` option allows you to specify a shell command to process the image before saving or embedding it as base64. The command should read the image data from the standard input and write the processed data to the standard output.

<details> <summary>Example: ImageMagick</summary>

```bash
process_cmd = "convert - -quality 85 -" -- compress the image with 85% quality
process_cmd = "convert - -resize 50% -" -- resize the image to 50% of its original size
process_cmd = "convert - -colorspace Gray -" -- convert the image to grayscale
```

Ensure the specified command and its dependencies are installed and accessible in your system's shell environment. The above examples require [ImageMagick](https://imagemagick.org/index.php) to be installed.

</details>

### Filetypes

Filetype specific options will override the default (or global) configuration.
Any option can be specified for a specific filetype.
Filetype specific options are determined by the _filetype_ (see `:help filetype`).
You can override settings for any filetype by specifying it as the key in your configuration:

```lua
filetypes = {
  <filetype> = { -- obtained from "set filetype?"
    -- add options here
  }
}
```

<details> <summary>Example: LaTeX-specific configuration</summary>

If you only want to use absolute file paths for LaTeX, then:

```lua
filetypes = {
  tex = {
    use_absolute_path = true
  }
}
```

</details>

### Overriding options for specific files, directories or custom triggers

Options can be overridden for specific files, directories or based on custom conditions.
This means that you can have different options for different projects, or even different files within the same project.

For files and directories, you can specify settings that apply to only a specific file or directory using its absolute path (e.g. `/home/user/project/README.md`).
You can also specify a general file or directory name (e.g. `README.md`) which will apply the settings to any `README.md` file.
For custom options, you can specify a _trigger_ function that returns a boolean value that is used to enable it.

The plugin evaluates the options in the following order:

1. Custom options
2. File specific options
3. Directory specific options
4. Filetype specific options
5. Default options

<details> <summary>Example</summary>

```lua
-- file specific options
files = {
  ["/path/to/specific/file.md"] = {
    template = "Custom template for this file",
  },
  ["README.md"] = {
    template = "Custom template for README.md files",
  },
},

-- directory specific options
dirs = {
  ["/path/to/project"] = {
    template = "Project specific template",
  },
},

-- custom options
custom = {
  {
    trigger = function() -- returns true to enable
      return vim.fn.strftime("%A") == "Monday"
    end,
    template = "Template for Mondays only",
  },
}
```

The options can be nested arbitrarily deep:

```lua
dirs = {
  ["/home/user/markdown"] = {
    template = "template for this project",

    filetypes = { -- filetype options nested inside dirs
      markdown = {
        template = "markdown template"
      }
    },

    files = { -- file options nested inside dirs
      ["readme.md"] = {
        dir_path = "images"
      },
    },
  },
}
```

</details>

### Project-specific settings with the `.img-clip.lua` file

Project-specific settings can be specified in a `.img-clip.lua` file in the root of your project.
The plugin will automatically load this file and use it to override the default settings.
If multiple files are found, the closest one to the current file (in any parent directory) will be used.

The `.img-clip.lua` should return a Lua table containing the options (similar to `opts` in lazy.nvim):

```lua
return {
  -- add options here
}
```

<details> <summary>Example</summary>

```lua
return {
  default = {
    template = "default template"
  },

  filetypes = {
    markdown = {
      template = "markdown template"
    }
  },
}
```

</details>

### Templates

Templates in the plugin use placeholders that are dynamically replaced with the correct values at runtime.
For available placeholders, see the following table and the [demonstration](#demonstration):

| Placeholder         | Description                                                                                             | Example                            |
| ------------------- | ------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| `$FILE_NAME`        | File name, including its extension.                                                                     | `image.png`                        |
| `$FILE_NAME_NO_EXT` | File name, excluding its extension.                                                                     | `image`                            |
| `$FILE_PATH`        | File path.                                                                                              | `/path/to/image.png`               |
| `$LABEL`            | Figure label, generated from the file name, converted to lower-case and with spaces replaced by dashes. | `the-image` (from `the image.png`) |
| `$CURSOR`           | Indicates where the cursor will be placed after insertion if `use_cursor_in_template` is true.          |                                    |

Templates can also be defined using functions with the above placeholders available as function parameters.

<details> <summary>Example</summary>

```lua
template = function(context)
  return "![" .. context.cursor .. "](" .. context.file_path .. ")"
end
```

</details>

## 🖱️ Drag and drop

The drag and drop feature enables users to drag images from the web browser or file explorer into the terminal to automatically embed them, in normal mode.
Drag and drop can also be enabled in insert mode by setting the `drag_and_drop.insert_mode` option to `true`.
For drag and drop to work properly, the terminal emulator must meet the following requirements:

1. The terminal emulator must paste the file path or URL to the image when it is dropped into the terminal.
2. The text must be inserted in [bracketed paste mode](https://cirw.in/blog/bracketed-paste), which allows Neovim to differentiate pasted text from typed-in text.
   This is required because the drag and drop feature is implemented by overriding `vim.paste()`.

A list of terminal emulators and their capabilities is given below.

<table>
  <thead>
    <tr>
      <th rowspan="2" style="text-align:center;">Terminal</th>
      <th colspan="2" style="text-align:center;">X11</th>
      <th colspan="2" style="text-align:center;">Wayland</th>
      <th colspan="2" style="text-align:center;">MacOS</th>
      <th colspan="2" style="text-align:center;">Windows</th>
    </tr>
    <tr>
      <th style="text-align:center;">File</th>
      <th style="text-align:center;">URL</th>
      <th style="text-align:center;">File</th>
      <th style="text-align:center;">URL</th>
      <th style="text-align:center;">File</th>
      <th style="text-align:center;">URL</th>
      <th style="text-align:center;">File</th>
      <th style="text-align:center;">URL</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><a href="https://github.com/kovidgoyal/kitty">Kitty</a></td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
    </tr>
    <tr>
      <td><a href="https://github.com/goblinfactory/konsole">Konsole</a></td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">❓️</td>
      <td style="text-align:center;">❓️</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
    </tr>
    <tr>
      <td><a href="https://github.com/alacritty/alacritty">Alacritty</a></td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">❌</td>
    </tr>
    <tr>
      <td><a href="https://github.com/wez/wezterm">Wezterm</a></td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">❓️</td>
      <td style="text-align:center;">❓️</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">❌</td>
    </tr>
    <tr>
      <td><a href="https://codeberg.org/dnkl/foot">Foot</a></td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
    </tr>
    <tr>
      <td><a href="https://en.wikipedia.org/wiki/Terminal_(macOS)">Terminal.app</a></td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
    </tr>
    <tr>
      <td><a href="https://iterm2.com/">iTerm.app</a></td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
    </tr>
    <tr>
      <td><a href="https://github.com/vercel/hyper">Hyper</a></td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">❓️</td>
      <td style="text-align:center;">❓️</td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">❌</td>
    </tr>
    <tr>
      <td><a href="https://en.wikipedia.org/wiki/Xterm">XTerm</a></td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
    </tr>
    <tr>
      <td><a href="https://apps.microsoft.com/detail/9N0DX20HK701">Windows Terminal</a></td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">✅</td>
      <td style="text-align:center;">✅</td>
    </tr>
    <tr>
      <td><a href="https://en.wikipedia.org/wiki/PowerShell">PowerShell</a></td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">❌</td>
    </tr>
    <tr>
      <td><a href="https://github.com/cmderdev/cmder">Cmder</a></td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">❌</td>
    </tr>
    <tr>
      <td><a href="https://github.com/Maximus5/ConEmu">ConEmu</a></td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">➖</td>
      <td style="text-align:center;">❌</td>
      <td style="text-align:center;">❌</td>
    </tr>
  </tbody>
</table>

> [!TIP]
> If you're having issues on Windows, try changing the default shell to `powershell` or `pwsh`. See `:h shell-powershell`.

> [!WARNING]
> MacOS URLs only work in Safari.

## 🔌 Integrations

### Telescope.nvim

The plugin can be integrated with [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) to provide a seamless way to select and embed images using Telescope's powerful fuzzy finding capabilities.

<details> <summary>Example configuration</summary>

```lua
function()
  local telescope = require("telescope.builtin")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  telescope.find_files({
    attach_mappings = function(_, map)
      local function embed_image(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        local filepath = entry[1]
        actions.close(prompt_bufnr)

        local img_clip = require("img-clip")
        img_clip.paste_image(nil, filepath)
      end

      map("i", "<CR>", embed_image)
      map("n", "<CR>", embed_image)

      return true
    end,
  })
end
```

The above function should be bound to a keymap, e.g. through lazy.nvim.

</details>

### Oil.nvim

The plugin also integrates with [oil.nvim](https://github.com/stevearc/oil.nvim), providing a convenient way to browse and select images using Oil's file explorer.

<details> <summary>Example configuration</summary>

```lua
function()
  local oil = require("oil")
  local filename = oil.get_cursor_entry().name
  local dir = oil.get_current_dir()
  oil.close()

  local img_clip = require("img-clip")
  img_clip.paste_image({}, dir .. filename)
end
```

The above function should be bound to a keymap, e.g. through lazy.nvim.

</details>

Alternatively, you can invoke img-clip.nvim directly from your oil.nvim configuration:

<details> <summary>Example configuration</summary>

```lua
keymaps = {
  ["<leader>p"] = function()
    local oil = require("oil")
    local filename = oil.get_cursor_entry().name
    local dir = oil.get_current_dir()
    oil.close()

    local img_clip = require("img-clip")
    img_clip.paste_image({}, dir .. filename)
  end,
}
```

</details>

## 🙌 Contributing

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue on the GitHub repository.
