local Component = require 'modules.component'
local dynamicRequire = require 'utils.dynamic-require'
local AnimationFactory = require 'components.animation-factory'
local overworldMapDefinition = dynamicRequire 'built.maps.overworld-map'
local F = require 'utils.functional'
local getFont = require 'components.font'

local function renderTextObjects(textObjects)
  for i=1, #textObjects do
    local o = textObjects[i]
    local font = getFont(o.fontfamily, o.pixelsize)
    love.graphics.setFont(font.font)
    love.graphics.setColor(1,1,1)
    love.graphics.print(o.text, o.x, o.y)
  end
end

local function renderPortalPoints(portalPoints)
  local graphic = AnimationFactory:newStaticSprite('gui-map-portal-point')
  local locationsVisited = Component.groups.locationsVisited.getAll()
  for i=1, #portalPoints do
    local p = portalPoints[i]
    if locationsVisited[p.properties.area] then
      love.graphics.setColor(1,1,1)
    else
      local c = 0.5
      love.graphics.setColor(c, c, c)
    end
    graphic:draw(p.x, p.y)
  end
end

local function renderPortalConnectionLines(connections)
  local pixel = AnimationFactory:newStaticSprite('pixel-white-1x1')
  love.graphics.setColor(1,1,1)
  for i=1, #connections do
    local l = connections[i]
    local rad = (l.rotation * math.pi) / 180
    pixel:draw(l.x, l.y, rad, l.width, l.height)
  end
end

return function()
  local textObjects = F.find(overworldMapDefinition.layers, function(l)
    return l.name == 'text'
  end).objects
  renderTextObjects(textObjects)

  local areaObjects = F.find(overworldMapDefinition.layers, function(l)
    return l.name == 'areas'
  end).objects
  renderPortalPoints(
    F.filter(areaObjects, function(o)
      return o.type == 'portalPoint'
    end)
  )

  renderPortalConnectionLines(
    F.filter(areaObjects, function(o)
      return o.type == 'connectionLine'
    end)
  )
end
