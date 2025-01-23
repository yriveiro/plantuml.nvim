local config = require 'plantuml.config'

local M = {}

local function locate(metadata)
  local screen_width = vim.o.columns
  local screen_height = vim.o.lines

  return {
    row = math.floor((screen_height - metadata.height) / 2),
    col = math.floor((screen_width - metadata.width) / 2),
  }
end

function M.geometry(size, screen)
  -- Terminal grid
  local term_cols, term_lines = vim.o.columns, vim.o.lines

  -- One cell's pixel size
  local cell_w = screen.width / term_cols
  local cell_h = screen.height / term_lines

  -- Convert image size to cell units
  local img_w_cells = size.width / cell_w
  local img_h_cells = size.height / cell_h

  -- Leave some margin
  local max_cols = term_cols - 4
  local max_lines = term_lines - 4

  -- Scale factors to fit
  local scale_w = max_cols / img_w_cells
  local scale_h = max_lines / img_h_cells

  local scale = math.min(scale_w, scale_h)

  -- Calculate final float-window size (cells)
  local win_w = math.floor(img_w_cells * scale)
  local win_h = math.floor(img_h_cells * scale)

  -- The same scale factor applies to the original pixels if you need that
  return {
    width = win_w,
    height = win_h,
    scale_factor = scale,
  }
end

function M.create(opts)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })

  local pos = locate(opts)

  local win_opts = {
    relative = 'editor',
    width = opts.width,
    height = opts.height,
    row = pos.row,
    col = pos.col,
    style = 'minimal',
    border = config.border,
    title = config.title,
    title_pos = config.title_pos,
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)
  return buf, win
end

return M
