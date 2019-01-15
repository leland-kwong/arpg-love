local testFiles = love.filesystem.getDirectoryItems('utils/test')

for _,file in ipairs(testFiles) do
  if file ~= 'index.lua' then
    require('utils.test.'..string.sub(file, 1, -5))
  end
end