local msgBus = require 'components.msg-bus'
local getNativeMousePos = require 'repl.shared.native-cursor-position'
local O = require 'utils.object-utils'
local Vec2 = require 'modules.brinevector'

local function getCursorPos()
  local pos = getNativeMousePos()
  local windowX, windowY = love.window.getPosition()
  return Vec2(
    pos.x - windowX,
    pos.y - windowY
  )
end

local function getUiCollisions(mouseX, mouseY, mouseCollision, collisionWorld)
  local _, _, cols, len = collisionWorld:move(mouseCollision, mouseX, mouseY, function()
    return 'cross'
  end)
  table.sort(cols, function(a, b)
    local ep1 = a.other.eventPriority or 1
    local ep2 = b.other.eventPriority or 1
    return ep1 > ep2
  end)
  return cols
end

local function setupListeners(getState, ColObj)
  return {
    msgBus.on('*', function(ev, msgType)
      local hoveredObject = nil
      local preventBubbleEvents = {}
      local recentlyFocusedItem
      local uiCollisions = getState().collisions

      local numCollisions = #uiCollisions

      local shouldBlurFocusedItemOnOutsideClick = 'MOUSE_PRESSED' == msgType and
        numCollisions == 0
      if shouldBlurFocusedItemOnOutsideClick then
        local previouslyFocusedItem = ColObj:setFocus()
        if previouslyFocusedItem then
          local blurHandler = previouslyFocusedItem.ON_BLUR
          if blurHandler then
            blurHandler(previouslyFocusedItem)
          end
        end
      end

      local function triggerUiEvents(msgType, obj)
        if (not preventBubbleEvents[msgType]) then
          local eventHandler = obj[msgType]
          if eventHandler then
            local returnVal = eventHandler(obj, ev, c) or O.EMPTY
            if returnVal.stopPropagation then
              preventBubbleEvents[msgType] = true
            end
          end
        end

        local shouldTriggerFocus = 'MOUSE_PRESSED' == msgType and
          not recentlyFocusedItem and
          not obj.focused

        if (shouldTriggerFocus) then
          recentlyFocusedItem = obj.focusable

          local previouslyFocusedItem = ColObj:getFocused()
          local isCurrentlyHovered = previouslyFocusedItem and previouslyFocusedItem.hovered

          if (not isCurrentlyHovered) and previouslyFocusedItem then
            local blurHandler = previouslyFocusedItem.ON_BLUR
            if blurHandler then
              blurHandler(previouslyFocusedItem)
            end
          end

          if (numCollisions > 1 and obj.focusable) or (numCollisions == 1) then
            ColObj:setFocus(obj)
            local focusHandler = obj.ON_FOCUS
            if focusHandler then
              focusHandler(obj)
            end
          end
        end

        if (not preventBubbleEvents.MOUSE_MOVE) then
          local hasMoved = getState().lastCursorPosition ~= getState().cursorPosition
          local mouseMoveHandler = obj.MOUSE_MOVE
          if hasMoved and mouseMoveHandler then
            local returnVal = mouseMoveHandler(obj, getState().cursorPosition) or O.EMPTY
            if returnVal.stopPropagation then
              preventBubbleEvents.MOUSE_MOVE = true
            end
          end
        end
      end

      local previouslyHovered = ColObj:getAllHovered()
      local itemsThatShouldNotTriggerLeaveEvent = {}
      -- clear previously hovered
      ColObj:clearHovered()

      -- handle hover state and event events
      for i=1, numCollisions do
        local c = uiCollisions[i]
        local item = c.other
        local handler = item.MOUSE_ENTER
        if (not previouslyHovered[item.id]) and handler then
          handler(item)
        end
        ColObj:setHover(item)
        itemsThatShouldNotTriggerLeaveEvent[item] = true
      end

      -- handle leave events
      for _,item in pairs(previouslyHovered) do
        local handler = item.MOUSE_LEAVE
        if handler and (not itemsThatShouldNotTriggerLeaveEvent[item]) then
          handler(item)
        end
      end

      -- [[ handle all other ui events ]]
      for i=1, numCollisions do
        local c = uiCollisions[i]
        local ref = c.other
        hoveredObject = hoveredObject or ref
        triggerUiEvents(msgType, ref)
      end

      local currentlyFocusedId = ColObj:getFocused()
      if (currentlyFocusedId and not ColObj:isHovered(currentlyFocusedId)) then
        triggerUiEvents(
          msgType,
          currentlyFocusedId
        )
      end
    end)
  }
end

return function(collisionContext)
  local state = {
    collisions = {},
    lastCursorPosition = Vec2(),
    cursorPosition = Vec2()
  }

  local mouseCollision = {}
  collisionContext.collisionWorld:add(mouseCollision, 0, 0, 1, 1)

  local listeners = setupListeners(function()
    return state
  end, collisionContext)

  return {
    update = function(dt)
      state.lastCursorPosition = state.cursorPosition
      local cursorPos = getCursorPos()
      state.cursorPosition = cursorPos
      state.collisions = getUiCollisions(
        cursorPos.x,
        cursorPos.y,
        mouseCollision,
        collisionContext.collisionWorld
      )
    end,
    cleanup = function()
      msgBus.off(listeners)
      collisionContext.collisionWorld:remove(mouseCollision)
    end
  }
end