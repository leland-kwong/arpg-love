return function(msgBus)
  -- custom cursor
  local cursorBaseSize = 18
  local cursorImages = {
    default = 'cursor-target',
    move = 'cursor-move',
  }
  local cursorsCache = {
    cursors = {},
    get = function(self, _type)
      local config = require 'config.config'
      local size = config.scale
      _type = _type or 'default'
      local cursorTypes = self.cursors[_type]
      if (not cursorTypes) then
        cursorTypes = {}
        self.cursors[_type] = cursorTypes
      end
      local cursor = cursorTypes[size]
      if (not cursor) then
        local fileName = cursorImages[_type]
        local sizeSuffix = size > 1 and ('-'..size..'x') or ''
        local cursorSize = cursorBaseSize * size
        cursor = love.mouse.newCursor('built/images/cursors/'..fileName..sizeSuffix..'.png', cursorSize/2, cursorSize/2)
        cursorTypes[size] = cursor
      end
      return cursor
    end
  }
  msgBus.CURSOR_SET = 'CURSOR_SET'
  msgBus.on(msgBus.CURSOR_SET, function(msg)
    love.mouse.setCursor(cursorsCache:get(msg.type))
  end)
end