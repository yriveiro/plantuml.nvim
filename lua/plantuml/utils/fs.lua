local sys = require 'plantuml.utils.sys'
local fmt = string.format

local Path = require 'plenary.path'

local M = {
  cache_path = Path:new(vim.fn.stdpath 'cache' .. '/plantuml/'):absolute(),
}

function M.load_module(name)
  local ok, module = pcall(require, name)

  assert(ok, fmt('plantuml missing dependency `%s`', name))

  return module
end

function M.touch_cache_dir(path)
  path = Path:new(path)
  path:mkdir { parents = true, exist_ok = true }
end

function M.libdisplay()
  return Path
    :new(vim.fn.stdpath 'data' .. '/plantuml/shared/libdisplay' .. sys.platform())
    :absolute()
end

function M.hash(path)
  local fd = io.open(path, 'rb')
  if not fd then
    return nil
  end

  local data = fd:read '*a'
  fd:close()

  return vim.fn.sha256(data)
end

return M
