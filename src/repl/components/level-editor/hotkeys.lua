local filterCall = require 'utils.filter-call'
local Grid = require 'utils.grid'

return function(actions, constants, states)
  local state = states.state
  local uiState = states.uiState

  local editorModes = constants.editorModes

  local handleResetSelectionKey = filterCall(function()
    actions:send('EDITOR_MODE_SET', editorModes.SELECT)
    actions:send('SELECTION_CLEAR')
  end, function(ev)
    return 'escape' == ev.key
  end)

  local handleEraseModeKey = filterCall(function()
    actions:send('EDITOR_MODE_SET', editorModes.ERASE)
    actions:send('SELECTION_CLEAR')
  end, function(ev)
    return 'e' == ev.key
  end)

  local handleCopyCutDeleteKey = function(ev)
    local inputState = require 'main.inputs.keyboard-manager'.state
    local keysPressed = inputState.keyboard.keysPressed
    local isCtrlKey = keysPressed.lctrl or keysPressed.rctrl
    local copyAction = 'c' == ev.key and isCtrlKey
    local cutAction = 'x' == ev.key and isCtrlKey
    local deleteAction = 'delete' == ev.key
    if copyAction or cutAction or deleteAction then
      local function convertGridSelection(gridSelection)
        local newSelection = {}
        local objectsGridToErase = {}
        local origin
        Grid.forEach(gridSelection, function(v, x, y)
          origin = origin or uiState.placementGridPosition
          local gridVal = Grid.get(state.placedObjects, x, y)
          if gridVal and (cutAction or copyAction) then
            local referenceId = gridVal.referenceId
            local objectData = ColObj:get(referenceId)
            local originOffsetX, originOffsetY = 1 - origin.x, 1 - origin.y
            Grid.set(newSelection, x + originOffsetX, y + originOffsetY, objectData)
          end
          if cutAction or deleteAction then
            Grid.set(objectsGridToErase, x, y, true)
          end
        end)
        return
          (not O.isEmpty(newSelection)) and newSelection or nil,
          (not O.isEmpty(objectsGridToErase)) and objectsGridToErase or nil
      end
      local nextSelection, objectsGridToErase = convertGridSelection(uiState.gridSelection)
      actions:send('PLACED_OBJECTS_ERASE', objectsGridToErase)
      actions:send('SELECTION_CLEAR')
      actions:send('SELECTION_SET', nextSelection)
    end
  end

  local handleNewLayerKey = function(ev)
    local inputState = require 'main.inputs.keyboard-manager'.state
    local keysPressed = inputState.keyboard.keysPressed
    local isShiftKey = keysPressed.lshift or keysPressed.rshift
    local isKeyComboMatch = ('n' == ev.key) and isShiftKey
    if (not isKeyComboMatch) then
      return
    end

    actions:send('LAYER_CREATE')
  end

  return function(self, ev)
    handleResetSelectionKey(ev)
    handleEraseModeKey(ev)
    handleCopyCutDeleteKey(ev)
    handleNewLayerKey(ev)
  end
end