local ffi = require 'ffi'

local fs = require 'plantuml.utils.fs'

local ERROR = vim.log.levels.ERROR

local M = {}

-- Cache for display information
local cache = {}

-- FFI declarations
ffi.cdef [[
  int get_display_count();
  void get_display_resolution(int displayIndex, int* width, int* height);
  int get_terminal_display();
]]

local lib = ffi.load(fs.libdisplay())

function M.resolution(display, force)
  display = display or lib.get_terminal_display()

  if display == -1 then
    vim.notify('plantuml: failed to detect terminal display', ERROR)
    return nil
  end

  if cache[display] and not force then
    return cache[display]
  end

  local w_ptr = ffi.new 'int[1]'
  local h_ptr = ffi.new 'int[1]'

  lib.get_display_resolution(display, w_ptr, h_ptr)

  local width, height = w_ptr[0], h_ptr[0]

  if width <= 0 or height <= 0 then
    vim.notify('plantuml: failed to get display resolution', ERROR)
    return nil
  end

  local entry = { [display] = { width = width, height = height } }

  vim.tbl_deep_extend('force', cache, entry)

  return entry[display]
end

function M.term_display()
  return lib.get_terminal_display()
end

function M.displays()
  return lib.get_display_count()
end

return M
