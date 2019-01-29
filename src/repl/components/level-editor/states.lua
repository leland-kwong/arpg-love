local dynamicRequire = require 'utils.dynamic-require'
local constants = dynamicRequire 'repl.components.level-editor.constants'
local editorModes = constants.editorModes
local Vec2 = require 'modules.brinevector'
local CreateState = dynamicRequire 'repl.components.level-editor.libs.create-state'

local state = CreateState({
  mapSize = Vec2(0, 0),
  loadDir = nil,
  saveDir = nil,
  layersList = {},
  placedObjects = {} -- 2d grid of objects by layer
}, {
  trackHistory = true
})

local uiState = CreateState({
  mousePosition = Vec2(0, 0),
  mouseGridPosition = Vec2(0, 0),
  placementGridPosition = Vec2(0, 0),
  fileStateContext = nil,
  loadedLayouts = {},
  editorMode = editorModes.SELECT,
  lastEditorMode = nil,
  lastPlacementGridPosition = nil,
  activeLayer = nil,
  translate = {
    startX = 0,
    startY = 0,
    dx = 0,
    dy = 0,
    x = 150,
    y = 100,

    zoomOffset = Vec2(0, 0),
  },
  scale = 1,
  textBoxCursorClock = 0,

  hoveredObject = {},
  selection = nil,
  gridSelection = nil,
  collisions = {},
  loadedLayoutObjects = {},

  getTranslate = function(self)
    local tx = self.translate
    return tx.x + tx.dx, tx.y + tx.dy
  end
})

return {
  state = state,
  uiState = uiState
}