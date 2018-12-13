return function(pkg)
  if package.loaded[pkg] then
    package.loaded[pkg] = nil
  end
  return require(pkg)
end