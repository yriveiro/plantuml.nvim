---@tag plantuml.png

---@brief [[
--- PNG is a utility module for extracting the dimensions (width and height)
--- from a PNG image file. It provides a simple API for working with binary files and
--- interpreting image metadata.
---
--- Getting started with PNG:
---   1. Ensure your Lua environment includes the `bit` library for bitwise operations.
---   2. Load the module using `local PNG = require("path.to.dimensions")`.
---   3. Use the `dimensions` method to get the width and height of a PNG file:
---      ```lua
---      local file = io.open("path/to/image.png", "rb")
---      local dimensions = png.dimensions(file)
---      if dimensions then
---          print("Width:", dimensions.width, "Height:", dimensions.height)
---      else
---          print("Failed to read image dimensions.")
---      end
---      file:close()
---      ```
---   4. Explore the helper methods `read` and `to_int` if you need lower-level access
---      to binary file reading and buffer interpretation.
---
--- <pre>
--- To find out more:
--- https://github.com/yriveiro/plantuml.nvim/blob/main/lua/plantuml/png.lua
---
--- :h plantuml.png
--- </pre>
---@brief ]]

---@see https://github.com/3rd/image.nvim/blob/6ffafab2e98b5bda46bf227055aa84b90add8cdc/lua/image/utils/dimensions.lua#L6
---@see https://github.com/edluffy/hologram.nvim/blob/f5194f71ec1578d91b2e3119ff08e574e2eab542/lua/hologram/fs.lua#L41
---@type plantuml.png
local M = {} ---@diagnostic disable-line: missing-fields

---Reads a specific number of bytes from a file.
---@param file file* File handle opened in binary mode.
---@param n integer Number of bytes to read.
---@return table|nil A table containing the read bytes as integers, or nil if fewer bytes are read or an error occurs.
local function read(file, n)
  local bytes = file:read(n)

  if not bytes then
    return nil
  end
  local t = { bytes:byte(1, n) }
  if #t < n then
    return nil
  end
  return t
end

---Converts 4 bytes from a buffer to a 32-bit integer.
---@param buf table Buffer containing bytes as integers.
---@param offset integer Offset in the buffer to start reading (default: 0).
---@return integer The resulting 32-bit integer.
local function to_int(buf, offset)
  local bor, lsh = bit.bor, bit.lshift
  offset = offset or 0
  return bor(
    lsh(buf[1 + offset], 24),
    lsh(buf[2 + offset], 16),
    lsh(buf[3 + offset], 8),
    buf[4 + offset]
  )
end

---Extracts the dimensions (width and height) of a PNG image file.
---This function reads the PNG file header to retrieve the dimensions.
---The PNG file format specifies that the width and height are stored
---as 4-byte integers starting at the 16th byte in the file.
---These bytes are part of the IHDR chunk, which is the first chunk in a valid PNG file.
---
---@param file file* File handle opened in binary mode.
---@return table|nil A table with `width` and `height` keys, or nil if the file is invalid, not a PNG, or an error occurs.
function M.dimensions(file)
  file:seek('set', 16)

  local buf = read(file, 8)

  if not buf then
    return nil
  end

  local width = to_int(buf, 0)
  local height = to_int(buf, 4)

  if not width or not height then
    return nil
  end

  return { width = width, height = height }
end

return M
