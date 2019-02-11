local globalState = require 'main.global-state'

local actions = {
  setBackgroundColor = function(color)
    globalState.backgroundColor = color
  end,
  updateGameClock = function(dt)
    globalState.gameClock = globalState.gameClock + dt
  end,
  setActiveLevel = function(levelInfo)
    globalState.activeLevel = {
      level = levelInfo.level,
      mapId = levelInfo.mapId
    }
  end,
  setSceneTitle = function(title)
    globalState.sceneTitle = title or ''
  end,
  setPlayerPortalInfo = function(info)
    assert(type(info) == 'table')
    assert(type(info.position) == 'table')
    assert(type(info.mapId) == 'string')
    globalState.playerPortal = info
  end,
  clearPlayerPortalInfo = function()
    globalState.playerPortal = {
      position = nil,
      mapId = nil
    }
  end,

  clearInteractableList = function()
    globalState.interactableList = {}
  end,
  setInteractable = function(item)
    globalState.interactableList[item] = true
  end
}

return function(action, payload)
  globalState.__allowMutation = true
  actions[action](payload)
  globalState.__allowMutation = false
end