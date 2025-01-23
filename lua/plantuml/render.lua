local M = {}

local Path = require 'plenary.path'

local fs = require 'plantuml.utils.fs'

local fmt = string.format

function M.render(puml, opts)
  local path = puml:absolute()

  -- Compute SHA-256 hash of the input file
  local sha256 = fs.hash(path)

  -- Define the cached PNG path using the hash
  local cached = Path:new(opts.cache.path .. sha256 .. '.png'):absolute()

  -- If the cached PNG exists, return its path
  if vim.uv.fs_stat(cached) then
    vim.notify 'plantuml: from cache'

    return cached
  end

  local f = io.popen(fmt('plantuml -tpng -pipe < %s > %s', path, cached))

  if f == nil then
    return nil
  end

  f:close()

  return cached
end

function M.image_size_pixels(sha256_img)
  local cmd = fmt('identify -format "%%wx%%h" %s', vim.fn.shellescape(sha256_img))

  local handle = io.popen(cmd)

  if not handle then
    vim.notify "Failed to execute ImageMagick's identify command"

    return nil
  end

  local result = handle:read '*a'

  handle:close()

  local width, height = result:match '(%d+)x(%d+)'

  if not width or not height then
    vim.notify 'Failed to parse image dimensions'

    return nil
  end

  return {
    width = tonumber(width),
    height = tonumber(height),
  }
end

return M
