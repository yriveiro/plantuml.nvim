local fs = require 'plantuml.utils.fs'

local M = {}

local config = {
  win = {
    border = 'single',
    title = {
      name = ' PlantUML Preview ',
      pos = 'center',
    },
  },
  zoom = {
    step = 1.2,
    scale = 1.0,
  },
  cache = {
    path = fs.cache_path,
  },
  cmd = 'plantuml',
}

function M.extend(opts)
  config = vim.tbl_deep_extend('force', config, opts)
end

return setmetatable(M, {
  __index = function(_, k)
    return config[k]
  end,
})
