local drawOrders = {
  'StatusIcons',
  'FrostSparkDraw',
  'BulletPreDraw',
  'BulletDraw',
  'BulletPostDraw',
  'LightWorldDraw',
  'SparkDraw',
  'MainMenu',
  'Dialog'
}

local parsedOrders = {
  __index = function(_, k)
    error('draw order '..k..' has not been registered')
  end
}

local startIndex = 10000

for i=1, #drawOrders do
  local key = drawOrders[i]
  local interval = 10
  parsedOrders[key] = (i * interval) + startIndex
end

return parsedOrders