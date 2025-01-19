local ffi = require 'ffi'
local image = require 'image'

-- FFI declarations for our display functions
ffi.cdef [[
  int get_display_count();
  void get_display_resolution(int displayIndex, int* width, int* height);
  int get_terminal_display();
]]

local lib_name = ffi.os == 'Windows' and 'display_resolution.dll'
  or ffi.os == 'OSX' and './shared/libdisplay.dylib'
  or './shared/libdisplay.so'

-- Load the display library
local display = ffi.load(lib_name)

---@class Plantuml
local M = {}

---@class ImageViewerConfig
---@field zoom_step number
---@field initial_scale number
---@field border string
---@field title string
---@field title_pos string

local defaults = {
  zoom_step = 1.2,
  initial_scale = 1.0,
  border = 'single',
  title = ' Image Viewer ',
  title_pos = 'center',
}

local config = defaults

---@class ImageDimensions
---@field width number
---@field height number

function M.dimensions(image_path)
  local cmd =
    string.format('identify -format "%%wx%%h" %s', vim.fn.shellescape(image_path))
  local handle = io.popen(cmd)
  if not handle then
    error "Failed to execute ImageMagick's identify command"
  end

  local result = handle:read '*a'
  handle:close()

  local width, height = result:match '(%d+)x(%d+)'
  if not width or not height then
    error 'Failed to parse image dimensions'
  end

  return {
    width = tonumber(width),
    height = tonumber(height),
  }
end

---Get the current display dimensions using FFI
---@return ImageDimensions
local function get_display_dimensions()
  local display_idx = display.get_terminal_display()
  if display_idx == -1 then
    error 'Failed to detect terminal display'
  end

  local w_ptr = ffi.new 'int[1]'
  local h_ptr = ffi.new 'int[1]'
  display.get_display_resolution(display_idx, w_ptr, h_ptr)

  local width, height = w_ptr[0], h_ptr[0]
  if width <= 0 or height <= 0 then
    error 'Failed to get display resolution'
  end

  return {
    width = width,
    height = height,
  }
end

---Calculate optimal window dimensions maintaining aspect ratio
---@param original_dimensions ImageDimensions
---@return ImageDimensions
local function calculate_optimal_dimensions(original_dimensions)
  -- Get screen dimensions in pixels
  local screen = get_display_dimensions()

  -- Get terminal grid dimensions
  local term_cols = vim.o.columns
  local term_lines = vim.o.lines

  -- Calculate cell size in pixels
  local cell_width = screen.width / term_cols
  local cell_height = screen.height / term_lines

  -- Convert image dimensions to cell units using actual pixel sizes
  local image_width_cells = original_dimensions.width / cell_width
  local image_height_cells = original_dimensions.height / cell_height

  -- Leave some margin for UI elements (subtract 4 from height and width)
  local max_width = term_cols - 4
  local max_height = term_lines - 4

  -- Calculate scaling factors for both dimensions
  local width_scale = max_width / image_width_cells
  local height_scale = max_height / image_height_cells

  -- Use the smaller scaling factor to maintain aspect ratio
  local scale = math.min(width_scale, height_scale)

  -- Calculate final dimensions in cells
  return {
    width = math.floor(image_width_cells * scale),
    height = math.floor(image_height_cells * scale),
  }
end

-- Rest of the functions remain the same
local function calculate_window_position(dimensions)
  local screen_width = vim.o.columns
  local screen_height = vim.o.lines

  return {
    row = math.floor((screen_height - dimensions.height) / 2),
    col = math.floor((screen_width - dimensions.width) / 2),
  }
end

local function create_float_window(buf, dimensions)
  local pos = calculate_window_position(dimensions)

  local win_opts = {
    relative = 'editor',
    width = dimensions.width,
    height = dimensions.height,
    row = pos.row,
    col = pos.col,
    style = 'minimal',
    border = config.border,
    title = config.title,
    title_pos = config.title_pos,
  }

  return vim.api.nvim_open_win(buf, true, win_opts)
end

local function setup_keymaps(bufnr, image_controls)
  local keymap_opts = { noremap = true, silent = true }
  local keymaps = {
    ['+'] = image_controls.zoom_in,
    ['-'] = image_controls.zoom_out,
    ['q'] = function()
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end,
    ['r'] = image_controls.reset_zoom,
  }

  for key, callback in pairs(keymaps) do
    vim.api.nvim_buf_set_keymap(
      bufnr,
      'n',
      key,
      '',
      vim.tbl_extend('force', keymap_opts, { callback = callback })
    )
  end
end

local function create_image_controls(original_dimensions, optimal_dimensions)
  local screen = get_display_dimensions()
  local cell_width = screen.width / vim.o.columns

  -- Calculate initial scale based on optimal dimensions and actual cell size
  local initial_scale = optimal_dimensions.width * cell_width / original_dimensions.width
  local current_scale = initial_scale

  local function update_image(scale)
    local bufnr = vim.api.nvim_get_current_buf()
    local images = image.get_images { buffer = bufnr }

    if #images > 0 then
      local new_dimensions = {
        width = original_dimensions.width * scale,
        height = original_dimensions.height * scale,
      }

      images[1].image_width = new_dimensions.width
      images[1].image_height = new_dimensions.height
      images[1]:render()

      vim.notify(
        string.format(
          'Scale: %.2fx (Dimensions: %dx%d)',
          scale,
          new_dimensions.width,
          new_dimensions.height
        )
      )
    end
  end

  return {
    zoom_in = function()
      current_scale = current_scale * config.zoom_step
      update_image(current_scale)
    end,

    zoom_out = function()
      current_scale = current_scale / config.zoom_step
      update_image(current_scale)
    end,

    reset_zoom = function()
      current_scale = initial_scale
      update_image(current_scale)
    end,
  }
end

function M.open_image_with_zoom(image_path)
  if not vim.fn.filereadable(image_path) then
    error(string.format('Image file not found: %s', image_path))
  end

  -- Get original image dimensions
  local original_dimensions = M.dimensions(image_path)
  vim.notify(
    string.format(
      'Original image dimensions: %dx%d',
      original_dimensions.width,
      original_dimensions.height
    )
  )

  -- Calculate optimal window dimensions using FFI-based display info
  local optimal_dimensions = calculate_optimal_dimensions(original_dimensions)
  vim.notify(
    string.format(
      'Optimal window dimensions: %dx%d cells',
      optimal_dimensions.width,
      optimal_dimensions.height
    )
  )

  -- Create and set up the buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })

  -- Create the window with optimal dimensions
  local win = create_float_window(buf, optimal_dimensions)

  -- Open the image
  vim.cmd('edit ' .. vim.fn.fnameescape(image_path))

  -- Set up image controls and keymaps
  local image_controls = create_image_controls(original_dimensions, optimal_dimensions)
  setup_keymaps(buf, image_controls)

  -- Apply initial scale
  image_controls.reset_zoom()

  return buf, win
end

function M.get_config()
  return vim.deepcopy(config)
end

function M.setup(opts)
  config = vim.tbl_deep_extend('force', defaults, opts or {})
end

return M
