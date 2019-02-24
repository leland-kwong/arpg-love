local msgBus = require 'components.msg-bus'

local cache = {}

msgBus.on(msgBus.NEW_GAME, function()
  cache = {}
end)

return {
  get = function(locationProps)
    local Dungeon = require 'modules.dungeon'
    local layoutType = locationProps.layoutType
    local mapId = cache[layoutType]
    if (not mapId) then
      mapId = Dungeon:new(locationProps)
      cache[layoutType] = mapId
    end
    return mapId
  end,
  clear = function()
    cache = {}
  end
}