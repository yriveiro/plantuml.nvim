local Path = require 'plenary.path'
local config = require 'plantuml.config'
local display = require 'plantuml.utils.display'
local fs = require 'plantuml.utils.fs'
local render = require 'plantuml.render'
local window = require 'plantuml.window'

local fmt = string.format
local ERROR = vim.log.levels.ERROR

local M = {}

function M.setup(opts)
  fs.load_module 'image'
  fs.load_module 'nio'

  config.extend(opts)

  fs.touch_cache_dir(config.cache.path)
end

function M.render(puml)
  if not puml then
    vim.notify('plantuml: file path empty', ERROR)

    return nil
  end

  puml = Path:new(puml)

  if not puml:exists() then
    vim.notify(fmt('plantuml: file %s do not exists', puml), ERROR)

    return nil
  end

  if puml:absolute():match '^.+%.([^%.]+)$' ~= 'puml' then
    vim.notify('plantuml: only supports puml extension', ERROR)
  end

  local img = render.render(puml, config)

  if img == nil then
    vim.notify(fmt('plantuml: render failed %s', img), ERROR)

    return nil
  end

  local size = render.image_size_pixels(img)

  local screen = display.term_display()
  local resolution = display.resolution(screen)
  local dim = window.geometry(size, resolution)

  local buf, win = window.create(dim)
  if not buf or not win then
    return nil, nil
  end

  vim.cmd('edit ' .. vim.fn.fnameescape(img))
end

return M
