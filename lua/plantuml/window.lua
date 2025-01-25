---@tag plantuml.window

---@brief [[
--- Window is a utility module designed for handling and displaying images within Neovim.
--- It provides functionality for scaling images to fit terminal dimensions, zooming in and out,
--- and rendering images in floating windows.
---
--- Getting started with window:
---   1. Ensure your Lua environment is set up to use this module.
---   2. Load the module using `local window = require("image_utils")`.
---   3. Use `window.geometry` to calculate scaled dimensions for an image.
---   4. Use `window.zoom` to zoom in or out on an image.
---   5. Use `window.create` to display an image in a floating window.
---
--- Example:
--- ```lua
--- local image_utils = require 'image_utils'
--- local size = { width = 800, height = 600 }
--- local term = { screen_cols = 80, screen_rows = 24, cell_width = 8, cell_height = 16 }
--- local geometry = image_utils.geometry(size, term)
--- print("Scaled width:", geometry.width, "Scaled height:", geometry.height)
---
--- local dim = { width = geometry.width, height = geometry.height, scale_factor = geometry.scale_factor }
--- local opts = { border = "rounded", title = "Image Viewer" }
--- local buf, win = image_utils.create(dim, opts)
--- ```
---
--- <pre>
--- To find out more:
--- https://github.com/yriveiro/plantuml.nvim/blob/main/lua/plantuml/window.lua
---
--- :h plantuml.window
--- </pre>
---@brief ]]

local image = require 'image'

---@type plantuml.window
local M = {} ---@diagnostic disable-line: missing-fields

---Calculates the screen coordinates to center the image on the editor.
---@param metadata table Table containing `width` and `height` keys of the image.
---@return table Coordinates for centering the image with `row` and `col` keys
local function locate(metadata)
  local screen_width = vim.o.columns
  local screen_height = vim.o.lines

  return {
    row = math.floor((screen_height - metadata.height) / 2),
    col = math.floor((screen_width - metadata.width) / 2),
  }
end

---Computes the scaled geometry for an image to fit within the terminal.
---@param size table Table containing the image's `width` and `height`.
---@param term table Table containing `screen_cols`, `screen_rows`, `cell_width`, and `cell_height` keys.
---@return table A table containing the scaled `width`, `height`, and `scale_factor`.
function M.geometry(size, term)
  local max_cols = term.screen_cols - 4
  local max_lines = term.screen_rows - 4

  local img_w_cells = size.width / term.cell_width
  local img_h_cells = size.height / term.cell_height

  local scale_w = max_cols / img_w_cells
  local scale_h = max_lines / img_h_cells
  local scale = math.min(scale_w, scale_h)

  return {
    width = math.floor(img_w_cells * scale),
    height = math.floor(img_h_cells * scale),
    scale_factor = scale,
  }
end

--- Adjusts the zoom level of the image based on the provided scale factor and operation.
--- @param scale_factor number The factor by which to scale the image.
--- @param operation string The zoom operation: either 'in' or 'out'.
function M.zoom(scale_factor, operation)
  if operation ~= 'in' and operation ~= 'out' then
    return
  end

  local factor = 1 + scale_factor

  if operation == 'out' then
    factor = 1 / factor
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local images = image.get_images { buffer = bufnr }

  images[1].image_width = images[1].image_width * factor
  images[1].image_height = images[1].image_height * factor

  images[1]:render()
end

--- Creates a new floating window for rendering an image.
--- @param dim table Table containing the image's `width`, `height`, and optional `scale_factor`.
--- @param opts table|nil Optional table containing window options:
---   - `border` (string|table): Border style.
---   - `title` (string): Title of the window.
---   - `title_pos` (string): Position of the title ('left', 'center', or 'right').
--- @return number, number The buffer number and window ID of the created window.
function M.create(dim, opts)
  opts = opts or {}

  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  local pos = locate(dim)

  local win_opts = {
    relative = 'editor',
    width = dim.width,
    height = dim.height,
    row = pos.row,
    col = pos.col,
    style = 'minimal',
    border = opts.border,
    title = opts.title,
    title_pos = opts.title_pos,
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  vim.keymap.set('n', '+', function()
    M.zoom(dim.scale_factor, 'in')
  end, { buffer = buf })

  vim.keymap.set('n', '-', function()
    M.zoom(dim.scale_factor, 'out')
  end, { buffer = buf })

  vim.keymap.set('n', 'q', function()
    vim.cmd 'quit'
  end, { buffer = buf })

  return buf, win
end

return M
