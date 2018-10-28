local drawOrders = {
  'FrostSparkDraw',
  'BulletPreDraw',
  'BulletDraw',
  'BulletPostDraw',
  'LightWorldDraw',
  'SparkDraw',
}

local parsedOrders = {
  __index = function(_, k)
    error('draw order '..k..' has not been registered')
  end
}

local startIndex = 10000

for i=1, #drawOrders do
  local key = drawOrders[i]
  parsedOrders[key] = i + startIndex
end

return parsedOrders