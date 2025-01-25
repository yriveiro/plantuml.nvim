---@tag plantuml

---@brief [[
--- PlantUML is a utility module for rendering PlantUML diagrams within Neovim.
--- It provides functionality to execute PlantUML commands, manage diagram caching,
--- and display diagrams in floating windows with proper scaling.
---
--- Getting started with PlantUML:
---   1. Ensure PlantUML and the required dependencies are installed and accessible in your environment.
---   2. Load the module using `local plantuml = require("plantuml")`.
---   3. Use `plantuml.setup` to configure the module with your preferences.
---   4. Use `plantuml.render` to render and display a PlantUML diagram.
---   5. Use the `:PlantUMLPreview` command to preview diagrams directly from the buffer.
---
--- Example:
--- ```lua
--- local plantuml = require 'plantuml'
---
--- plantuml.setup {
---   cmd = 'plantuml',
---   cache = { path = vim.fn.stdpath('cache') .. '/plantuml/' },
--- }
---
--- local diagram_path = '/path/to/diagram.puml'
--- plantuml.render(diagram_path)
--- ```
---
--- <pre>
--- To find out more:
--- https://github.com/yriveiro/plantuml.nvim
---
--- :h plantuml
--- </pre>
---@brief ]]

local image = require 'image'
local term = require 'image.utils.term'

local png = require 'plantuml.png'
local window = require 'plantuml.window'

local fmt = string.format
local ERROR = vim.log.levels.ERROR

local M = {}

---@type plantuml.config
local config = {
  win = {
    border = 'single',
    title = {
      name = ' PlantUML Preview ',
      pos = 'center', -- TODO: this os noop at the moment.
    },
  },
  cache = {
    path = vim.fs.joinpath(tostring(vim.fn.stdpath 'cache'), '/plantuml/'),
  },
  cmd = 'plantuml',
}

---Loads a required module and raises an error if the module is not available.
---@param name string Name of the module to load.
---@return any Loaded module.
local function load_module(name)
  local ok, module = pcall(require, name)

  assert(ok, fmt('plantuml: missing dependency `%s`', name))

  return module
end

---Executes the PlantUML command to render a diagram.
---@param puml string Path to the PlantUML file.
---@param opts table Configuration options.
---@return string|nil Path to the generated PNG file or `nil` on failure.
local function exec(puml, opts)
  local fd = io.open(puml, 'rb')

  if not fd then
    return nil
  end

  local data = fd:read '*a'
  local sha256 = vim.fn.sha256(data)

  fd:close()

  local output = vim.fs.joinpath(opts.cache.path, sha256 .. '.png')

  if vim.uv.fs_stat(output) then
    return output
  end

  fd = io.popen(fmt('%s -tpng -pipe < %s > %s', opts.cmd, puml, output))
  if fd == nil then
    vim.notify(fmt('plantuml: failed to execute: %s', puml), ERROR)

    return nil
  end

  fd:close()

  return output
end

--- Renders a PlantUML diagram and displays it in a floating window.
--- @param puml string Path to the PlantUML file.
function M.render(puml)
  local output = exec(puml, config)

  if not output then
    vim.notify(fmt('plantuml: render failed %s', puml), ERROR)

    return nil
  end

  local fd = io.open(output, 'r')

  if not fd then
    vim.notify(fmt('plantuml: %s is not readable', output), ERROR)

    return nil
  end

  local size = png.dimensions(fd)

  if not size then
    return nil
  end

  local screen = term.get_size()
  local dim = window.geometry(size, screen)

  local buf, win = window.create(dim, config)

  if not buf or not win then
    return nil
  end

  local graph = image.from_file(output, { window = win, buffer = buf })

  if not graph then
    vim.notify(fmt('plantuml: image from file failed %s', graph), ERROR)

    return nil
  end

  graph.image_width = graph.image_width * dim.scale_factor
  graph.image_height = graph.image_height * dim.scale_factor

  graph:render()
end

--- Sets up the PlantUML module with user-defined options.
--- @param opts table Configuration options to override defaults.
function M.setup(opts)
  load_module 'image'

  config = vim.tbl_deep_extend('force', config, opts)

  vim.fn.mkdir(config.cache.path, 'p')

  vim.api.nvim_create_user_command('PlantUMLPreview', function()
    local puml = vim.api.nvim_buf_get_name(0)
    require('plantuml').render(puml)
  end, {})
end

return M
