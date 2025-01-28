local M = {}

M.drag_and_drop = false
M.config_file = "Default"
M.sorted_files = {}
M.sorted_dirs = {}
M.configs = {}
M.api_opts = {}
M.opts = {}

local defaults = {
  default = {
    -- file and directory options
    dir_path = "assets", ---@type string
    extension = "png", ---@type string
    file_name = "%Y-%m-%d-%H-%M-%S", ---@type string
    use_absolute_path = false, ---@type boolean
    relative_to_current_file = false, ---@type boolean

    -- template options
    template = "$FILE_PATH", ---@type string
    url_encode_path = false, ---@type boolean
    relative_template_path = true, ---@type boolean
    use_cursor_in_template = true, ---@type boolean
    insert_mode_after_paste = true, ---@type boolean

    -- prompt options
    prompt_for_file_name = true, ---@type boolean
    show_dir_path_in_prompt = false, ---@type boolean

    -- base64 options
    max_base64_size = 10, ---@type number
    embed_image_as_base64 = false, ---@type boolean

    -- image options
    process_cmd = "", ---@type string
    copy_images = false, ---@type boolean
    download_images = true, ---@type boolean
    extra_image_types = {}, ---@type table

    -- drag and drop options
    drag_and_drop = {
      enabled = true, ---@type boolean
      insert_mode = false, ---@type boolean
    },
  },

  -- filetype specific options
  filetypes = {
    markdown = {
      url_encode_path = true, ---@type boolean
      template = "![$CURSOR]($FILE_PATH)", ---@type string
      download_images = false, ---@type boolean
    },

    vimwiki = {
      url_encode_path = true, ---@type boolean
      template = "![$CURSOR]($FILE_PATH)", ---@type string
      download_images = false, ---@type boolean
    },

    html = {
      template = '<img src="$FILE_PATH" alt="$CURSOR">', ---@type string
    },

    tex = {
      relative_template_path = false, ---@type boolean
      template = [[
\begin{figure}[h]
  \centering
  \includegraphics[width=0.8\textwidth]{$FILE_PATH}
  \caption{$CURSOR}
  \label{fig:$LABEL}
\end{figure}
    ]], ---@type string

      extra_image_types = { "pdf" }, ---@type table
    },

    typst = {
      template = [[
#figure(
  image("$FILE_PATH", width: 80%),
  caption: [$CURSOR],
) <fig-$LABEL>
    ]], ---@type string
    },

    rst = {
      template = [[
.. image:: $FILE_PATH
   :alt: $CURSOR
   :width: 80%
    ]], ---@type string
    },

    asciidoc = {
      template = 'image::$FILE_PATH[width=80%, alt="$CURSOR"]', ---@type string
    },

    org = {
      template = [=[
#+BEGIN_FIGURE
[[file:$FILE_PATH]]
#+CAPTION: $CURSOR
#+NAME: fig:$LABEL
#+END_FIGURE
    ]=], ---@type string
    },
  },

  -- file, directory, and custom triggered options
  files = {}, ---@type table
  dirs = {}, ---@type table
  custom = {}, ---@type table
}

defaults.filetypes.plaintex = defaults.filetypes.tex
defaults.filetypes.rmd = defaults.filetypes.markdown
defaults.filetypes.quarto = defaults.filetypes.markdown
defaults.filetypes.md = defaults.filetypes.markdown

---sorts the files and dirs tables by length of the path
---so more specific paths have priority over less specific paths
---@param opts table
---@return table
M.sort_config = function(opts)
  local function sort_keys(tbl)
    local sorted_keys = {}

    for key in pairs(tbl) do
      table.insert(sorted_keys, key)
    end

    table.sort(sorted_keys, function(a, b)
      return #a > #b
    end)

    return sorted_keys
  end

  M.sorted_files = sort_keys(opts["files"])
  M.sorted_dirs = sort_keys(opts["dirs"])

  return opts
end

---get the config
---can be either the default config or the config from the config file
---@return table
M.get_config = function()
  -- use cached config if available
  local dir_path = vim.fn.expand("%:p:h")
  if M.configs[dir_path] and M.configs[dir_path] ~= {} then
    return M.configs[dir_path]

  -- no cached config file found, use default config
  elseif M.configs[dir_path] == {} then
    M.config_file = "Default"
    return M.opts
  end

  -- find config file in the current directory or any parent directory
  local config_file = vim.fn.findfile(".img-clip.lua", ".;")
  if config_file ~= "" then
    local success, output = pcall(dofile, config_file)

    if success then
      local opts = vim.tbl_deep_extend("force", {}, defaults, output)
      M.configs[dir_path] = M.sort_config(opts)
      M.config_file = config_file
      return M.configs[dir_path]
    else
      M.configs[dir_path] = {}
      print("Error loading config file: " .. output)
    end
  end

  -- use default config if no config file is found
  M.config_file = "Default"
  return M.opts
end

---recursively gets the value of the option (e.g. "default.debug")
---@param key string
---@param opts table
---@return string | nil
local function recursive_get_opt(key, opts)
  local keys = vim.split(key, ".", { plain = true, trimempty = true })

  for _, k in pairs(keys) do
    if opts and opts[k] ~= nil then
      opts = opts[k]
    else
      return nil
    end
  end

  return opts
end

---get the value of the option, executing it if it's a function
---@param val any
---@param args? table
---@return string | nil
local function get_val(val, args)
  if val == nil then
    return nil
  elseif type(val) == "function" then
    return val(args or {})
  else
    return val
  end
end

---get the option from the custom table
---@param key string
---@param args? table
---@return string | nil
local function get_custom_opt(key, opts, args)
  if opts["custom"] == nil then
    return nil
  end

  for _, config_opts in ipairs(opts["custom"]) do
    if config_opts["trigger"] and get_val(config_opts["trigger"]) then
      return M.get_opt(key, args, config_opts)
    end
  end
end

---get the option from the files table
---@param key string
---@param args? table
---@return string | nil
local function get_file_opt(key, opts, args, file)
  if opts["files"] == nil then
    return nil
  end

  local function file_matches(f1, f2)
    return string.sub(f1:lower(), -#f2:lower()) == f2:lower()
  end

  for _, config_file in ipairs(M.sorted_files) do
    if file_matches(file, config_file) or file_matches(file, vim.fn.resolve(vim.fn.expand(config_file))) then
      return M.get_opt(key, args, opts["files"][config_file])
    end
  end

  return nil
end

---get the option from the dirs table
---@param key string
---@param args? table
---@return string | nil
local function get_dir_opt(key, opts, args, dir)
  if opts["dirs"] == nil then
    return nil
  end

  local function dir_matches(d1, d2)
    return string.find(d1:lower(), d2:lower(), 1, true)
  end

  for _, config_dir in ipairs(M.sorted_dirs) do
    if dir_matches(dir, config_dir) or dir_matches(dir, vim.fn.resolve(vim.fn.expand(config_dir))) then
      return M.get_opt(key, args, opts["dirs"][config_dir])
    end
  end

  return nil
end

---get the option from the filetypes table
---@param key string
---@return string | nil
local function get_filetype_opt(key, opts, ft)
  return recursive_get_opt("filetypes." .. ft .. "." .. key, opts)
end

---get the option from the default table
---@param key string
---@return string | nil
local function get_default_opt(key, opts)
  return recursive_get_opt("default." .. key, opts)
end

---get the option from the main opts table
---@param key string
---@return string | nil
local function get_unscoped_opt(key, opts)
  return recursive_get_opt(key, opts)
end

---@param key string: The key, may be nested (e.g. "default.debug")
---@param args? table: Args that should be passed to the option function
---@param opts? table: Opts passed explicitly to the function
---@return string | table | nil
M.get_opt = function(key, args, opts)
  -- use explicit opts if provided
  -- otherwise, try to get the value from the api_opts
  -- and then from the config file
  if not opts then
    local val = M.get_opt(key, args, M.api_opts)
    if val ~= nil then
      return val
    end
    return M.get_opt(key, args, M.get_config())
  end

  -- if we're in drag and drop mode, try to get drag and drop options
  -- and then fall back to the regular options if they're not found
  if M.drag_and_drop and not key:find("drag_and_drop") then
    local val = M.get_opt("drag_and_drop." .. key, args, M.opts)
    if val ~= nil then
      return val
    end
  end

  local val = get_custom_opt(key, opts, args)
  if val == nil then
    val = get_file_opt(key, opts, args, vim.fn.expand("%:p"))
  end
  if val == nil then
    val = get_dir_opt(key, opts, args, vim.fn.expand("%:p:h"))
  end
  if val == nil then
    val = get_filetype_opt(key, opts, vim.bo.filetype)
  end
  if val == nil then
    val = get_default_opt(key, opts)
  end
  if val == nil then
    val = get_unscoped_opt(key, opts)
  end

  return get_val(val, args)
end

---@param config_opts? table
function M.setup(config_opts)
  M.opts = vim.tbl_deep_extend("force", {}, defaults, config_opts or {})
  M.opts = M.sort_config(M.opts)
end

M.setup()

M.print_config = function()
  local config = M.get_config()

  print("Config file: " .. M.config_file)
  vim.print(config)
end

return M
