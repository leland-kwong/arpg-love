local dynamicRequire = require 'utils.dynamic-require'
local O = require 'utils.object-utils'
local Grid = dynamicRequire 'utils.grid'
local ActionSystem = dynamicRequire 'repl.components.level-editor.libs.action-system'
local Component = require 'modules.component'

return function(states, constants)
  local state = states.state
  local uiState = states.uiState

  local actions = ActionSystem()
  return actions:addActions({
    LAYER_CREATE = function()
      local nextState = O.clone(state.placedObjects)
      local layerId = Component.newId()
      nextState[layerId] = {}

      local layersListCopy = O.clone(state.layersList)
      table.insert(layersListCopy, {
        id = layerId,
        label = 'layer-'..layerId
      })
      state:set('layersList', layersListCopy)
    end,

    LAYER_SELECT = function(layerId)
      uiState:set('activeLayer', layerId)
    end,

    EDITOR_MODE_SET = function(mode)
      if not constants.editorModes[mode] then
        error('invalid mode', mode)
      end
      uiState:set('editorMode', mode)
    end,

    -- selection must be a 2-d array
    SELECTION_SET = function(selection)
      uiState:set('selection', selection)
    end,

    SELECTION_CLEAR = function()
      uiState:set('selection', nil)
      uiState:set('gridSelection', nil)
    end,

    GRID_SELECTION_SET = function(selection)
      uiState:set('gridSelection', selection)
    end,

    HOVERED_OBJECT_SET = function(obj)
      uiState:set('hoveredObject', obj)
    end,

    PLACED_OBJECTS_ERASE = function(objectsGridToErase)
      if (not objectsGridToErase) then
        return
      end
      local nextObjectState = O.deepCopy(state.placedObjects)
      Grid.forEach(objectsGridToErase, function(_, x, y)
        Grid.set(nextObjectState, x, y, nil)
      end)
      state:set('placedObjects', nextObjectState)
    end,

    PLACED_OBJECTS_UPDATE = function(nextGridSelection)
      if (not nextGridSelection) then
        return
      end

      local ngs = nextGridSelection
      local nextObjectState = O.deepCopy(state.placedObjects)
      Grid.forEach(ngs.selection, function(v, localX, localY)
        local updateX, updateY = ngs.x + (localX - 1), ngs.y + (localY - 1)
        local objectToAdd = {
          id = Component.newId(),
          referenceId = v.id,
        }
        Grid.set(nextObjectState, updateX, updateY, objectToAdd)
      end)
      state:set('placedObjects', nextObjectState)
    end
  })
end