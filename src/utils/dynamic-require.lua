return function(pkg)
  local oPkg = package.loaded[pkg]
  package.loaded[pkg] = nil
  local newModule = require(pkg)
  package.loaded[pkg] = oPkg
  return newModule
end