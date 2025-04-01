local M = {}

--- Check if the MIME type is a supported format
--- @param mime_type string
--- @param supported_formats string[]
--- @return boolean
M.is_supported_mime_type = function(mime_type, supported_formats)
  local mime_fmts = M.formats_from_mime_type(mime_type)

  -- Handle unknown formats
  if mime_fmts == nil then
    return false
  end

  -- Convert into a set (https://www.lua.org/pil/11.5.html)
  local valid_formats = {}
  for _, format in ipairs(supported_formats) do
    valid_formats[format] = true
  end

  for _, fmt in pairs(mime_fmts) do
    if valid_formats[fmt] ~= nil then
      return true
    end
  end

  return false
end

-- Return a table of the image format extensions corresponding to this mime type
--- @return string[]
M.formats_from_mime_type = function(mime_type)
  local mime_fmts = M.mime_types[mime_type]

  if type(mime_fmts) == "string" then
    -- Make a table, because multiple formats could map to the MIME type
    mime_fmts = { mime_fmts }
  end

  return mime_fmts
end

-- A table of common MIME types, mapping to their file types
-- Based of the [MDN guide](https://developer.mozilla.org/en-US/docs/Web/HTTP/MIME_types/Common_types)
-- Some common non-standard MIME types called out in the notes of the MDN table have been included too.
M.mime_types = {

  ["audio/aac"] = "aac",
  ["application/x-abiword"] = "abw",
  ["image/apng"] = "apng",
  ["application/x-freearc"] = "arc",
  ["image/avif"] = "avif",
  ["video/x-msvideo"] = "avi",
  ["application/vnd.amazon.ebook"] = "azw",
  ["application/octet-stream"] = "bin",
  ["image/bmp"] = "bmp",
  ["application/x-bzip"] = "bz",
  ["application/x-bzip2"] = "bz2",
  ["application/x-cdf"] = "cda",
  ["application/x-csh"] = "csh",
  ["text/css"] = "css",
  ["text/csv"] = "csv",
  ["application/msword"] = "doc",
  ["application/vnd.openxmlformats-officedocument.wordprocessingml.document"] = "docx",
  ["application/vnd.ms-fontobject"] = "eot",
  ["application/epub+zip"] = "epub",
  ["application/gzip"] = "gz",
  -- NOTE: Windows and macOS upload `.gz` files with the non-standard MIME type `application/x-gzip`.
  ["application/x-gzip"] = "gz",
  ["image/gif"] = "gif",
  ["text/html"] = { "htm", "html" },
  ["image/vnd.microsoft.icon"] = "ico",
  ["text/calendar"] = "ics",
  ["application/java-archive"] = "jar",
  ["image/jpeg"] = { "jpeg", "jpg" },
  --(Specifications: HTML and RFC 9239)
  ["text/javascript "] = "js",
  ["application/json"] = "json",
  ["application/ld+json"] = "jsonld",
  ["audio/midi, audio/x-midi"] = { "mid", "midi" },
  ["text/javascript"] = "mjs",
  ["audio/mpeg"] = "mp3",
  ["video/mp4"] = "mp4",
  ["video/mpeg"] = "mpeg",
  ["application/vnd.apple.installer+xml"] = "mpkg",
  ["application/vnd.oasis.opendocument.presentation"] = "odp",
  ["application/vnd.oasis.opendocument.spreadsheet"] = "ods",
  ["application/vnd.oasis.opendocument.text"] = "odt",
  ["audio/ogg"] = { "oga", "opus" },
  ["video/ogg"] = "ogv",
  ["application/ogg"] = "ogx",
  ["font/otf"] = "otf",
  ["image/png"] = "png",
  ["application/pdf"] = "pdf",
  ["application/x-httpd-php"] = "php",
  ["application/vnd.ms-powerpoint"] = "ppt",
  ["application/vnd.openxmlformats-officedocument.presentationml.presentation"] = "pptx",
  ["application/vnd.rar"] = "rar",
  ["application/rtf"] = "rtf",
  ["application/x-sh"] = "sh",
  ["image/svg+xml"] = "svg",
  ["application/x-tar"] = "tar",
  ["image/tiff"] = { "tif", "tiff" },
  ["video/mp2t"] = "ts",
  ["font/ttf"] = "ttf",
  ["text/plain"] = "txt",
  ["application/vnd.visio"] = "vsd",
  ["audio/wav"] = "wav",
  ["audio/webm"] = "weba",
  ["video/webm"] = "webm",
  ["image/webp"] = "webp",
  ["font/woff"] = "woff",
  ["font/woff2"] = "woff2",
  ["application/xhtml+xml"] = "xhtml",
  ["application/vnd.ms-excel"] = "xls",
  ["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"] = "xlsx",
  -- NOTE: `application/xml` is recommended as of RFC 7303 (section 4.1), but `text/xml` is still used sometimes.
  -- You can assign a specific MIME type to a file with `.xml` extension depending on how its contents are meant to be interpreted.
  -- For instance, an Atom feed is `application/atom+xml`, but `application/xml` serves as a valid default.
  ["application/xml"] = "xml",
  ["text/xml"] = "xml",
  ["application/vnd.mozilla.xul+xml"] = "xul",
  ["application/zip"] = "zip",
  -- Note, Windows uploads `.zip` files with the non-standard MIME type application/x-zip-compressed.
  ["application/x-zip-compressed"] = "zip",
  ["video/3gpp"] = "3gp",
  -- `audio/3gpp` if it doesn't contain video
  ["audio/3gpp"] = "3gp",
  ["video/3gpp2"] = "3g2",
  -- `audio/3gpp2` if it doesn't contain video
  ["audo/3gpp2"] = "3g2",
  ["application/x-7z-compressed"] = "7z",
}

return M
