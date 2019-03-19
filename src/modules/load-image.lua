local imagesCache = {}
local function loadImage(path)
  local img = imagesCache[path]
  if (not img) then
    img = love.graphics.newImage(path)
    img:setFilter('nearest')
    imagesCache[path] = img
  end
  return img
end

return loadImage