local fn = vim.fn
local health = vim.health
local is_win = vim.fn.has 'win32' == 1

local dependencies = {
  {
    name = 'plantuml',
    binaries = { 'plantuml' },
    args = { '-version' },
    url = '[plantuml](https://plantuml.com/starting)',
    optional = false,
  },
}

local required_plugins = {
  { name = 'plenary', optional = false },
}

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

local function is_plugin_installed(plugin_name)
  return pcall(require, plugin_name)
end

local M = {}

function M.check()
  health.start 'Checking for required plugins'

  for _, plugin in ipairs(required_plugins) do
    local installed = is_plugin_installed(plugin.name)
    if installed then
      health.ok(plugin.name .. ' installed.')
    else
      local message = plugin.name .. ' not found.'
      if plugin.optional then
        health.warn(message)
      else
        health.error(message)
      end
    end
  end

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
