return function(states, actions, editorModes, ColObj, msgBus, O)
  local state = states.state
  local uiState = states.uiState

  return msgBus.on('*', function(ev, msgType)
    local hoveredObject = nil
    local uiCollisions = uiState.collisions
    local preventBubbleEvents = {}
    local recentlyFocusedItem

    local numCollisions = #uiCollisions

    local shouldBlurFocusedItemOnOutsideClick = 'MOUSE_PRESSED' == msgType and
      numCollisions == 0
    if shouldBlurFocusedItemOnOutsideClick then
      local previouslyFocusedItem = ColObj:get(ColObj:setFocus())
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
        not ColObj:isFocused(obj.id)

      if (shouldTriggerFocus) then
        recentlyFocusedItem = obj.focusable

        local previouslyFocusedItemId = ColObj:getFocused()
        local previouslyFocusedItem = ColObj:get(previouslyFocusedItemId)
        local isCurrentlyHovered = ColObj:isHovered(previouslyFocusedItemId)

        if (not isCurrentlyHovered) and previouslyFocusedItem then
          local blurHandler = previouslyFocusedItem.ON_BLUR
          if blurHandler then
            blurHandler(previouslyFocusedItem)
          end
        end

        if (numCollisions > 1 and obj.focusable) or (numCollisions == 1) then
          ColObj:setFocus(obj.id)
          local focusHandler = obj.ON_FOCUS
          if focusHandler then
            focusHandler(obj)
          end
        end
      end

      if (not preventBubbleEvents.MOUSE_MOVE) then
        local mouseMoveHandler = obj.MOUSE_MOVE
        if mouseMoveHandler then
          local returnVal = mouseMoveHandler(obj, ev) or O.EMPTY
          if returnVal.stopPropagation then
            preventBubbleEvents.MOUSE_MOVE = true
          end
        end
      end
    end

    -- clear previously hovered
    ColObj:clearHovered()

    for i=1, numCollisions do
      local c = uiCollisions[i]
      ColObj:setHover(c.other.id)
    end

    -- [[ handle ui events ]]
    for i=1, numCollisions do
      local c = uiCollisions[i]
      local obj = c.other
      hoveredObject = hoveredObject or obj
      triggerUiEvents(msgType, obj)
    end

    local currentlyFocusedId = ColObj:getFocused()
    local currentlyFocusedItem = ColObj:get(currentlyFocusedId)
    if ((not ColObj:isHovered(currentlyFocusedId)) and currentlyFocusedItem) then
      triggerUiEvents(
        msgType,
        currentlyFocusedItem
      )
    end

    actions:send('HOVERED_OBJECT_SET', hoveredObject)
    if hoveredObject and hoveredObject.selectable then
      actions:send('EDITOR_MODE_SET', editorModes.SELECT)
    end
  end)
end