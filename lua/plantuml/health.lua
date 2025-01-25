local fn = vim.fn
local health = vim.health
local is_win = vim.fn.has 'win32' == 1

---List of dependencies to check.
---Each dependency contains its name, required binaries, arguments, and other properties.
---@table dependencies
local dependencies = {
  {
    name = 'plantuml',
    binaries = { 'plantuml' },
    args = { '-version' },
    url = '[plantuml](https://plantuml.com/starting)',
    optional = false,
  },
}

---Checks if a binary exists and optionally retrieves its version.
---@param binary string The name of the binary to check.
---@param args table A table of command-line arguments for the binary (optional).
---@return boolean Whether the binary exists.
---@return string|nil The version information if available, or `nil` if not.
local function check_binary(binary, args)
  if is_win then
    binary = binary .. '.exe'
  end

  if fn.executable(binary) ~= 1 then
    return false, nil
  end

  local cmd = binary .. ' ' .. table.concat(args or {}, ' ')
  local handle = io.popen(cmd)
  if not handle then
    return false, nil
  end

  local version = handle:read '*a'
  handle:close()
  return true, version
end

local M = {}

---Performs a health check for external dependencies.
---Iterates over all declared dependencies and checks their availability.
---Provides health report messages based on the results.
function M.check()
  health.start 'Checking external dependencies'

  for _, dep in ipairs(dependencies) do
    local ok, version = check_binary(dep.binaries[1], dep.args)
    if not ok then
      local message = dep.name .. ': not found.'
      if dep.optional then
        health.warn(message .. ' Install ' .. dep.url .. ' for extended capabilities')
      else
        health.error(message .. ' Required for core functionality.')
      end
    else
      local version_str = '(unknown version)'
      if version then
        local first_line = version:match '[^\n]+'
        if first_line then
          version_str = first_line
        end
      end
      health.ok(string.format('%s: found %s', dep.name, version_str))
    end
  end
end

return M
