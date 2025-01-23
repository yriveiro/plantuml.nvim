local M = {}

function M.platform()
  if jit.os:lower() == 'mac' or jit.os:lower() == 'osx' then
    return '.dylib'
  end
  if jit.os:lower() == 'windows' then
    return '.dll'
  end

  return '.so'
end

return M
