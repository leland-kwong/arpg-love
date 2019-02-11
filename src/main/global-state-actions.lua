local actions = {
  setBackgroundColor = function(state, color)
    state.backgroundColor = color
  end,
  updateGameClock = function(state, dt)
    state.gameClock = state.gameClock + dt
  end,
  setActiveLevel = function(state, levelInfo)
    state.activeLevel = {
      level = levelInfo.level,
      mapId = levelInfo.mapId
    }
  end,
  setSceneTitle = function(state, title)
    state.sceneTitle = title or ''
  end,
  setPlayerPortalInfo = function(state, info)
    assert(type(info) == 'table')
    assert(type(info.position) == 'table')
    assert(type(info.mapId) == 'string')
    state.playerPortal = info
  end,
  clearPlayerPortalInfo = function(state)
    state.playerPortal = {
      position = nil,
      mapId = nil
    }
  end,

  clearInteractableList = function(state)
    state.interactableList = {}
  end,
  setInteractable = function(state, item)
    state.interactableList[item] = true
  end
}

local globalState = require 'main.global-state'
return function(action, payload)
  local reducer = actions[action]
  local state = globalState.getState()
  globalState.replaceState(
    reducer(state, payload) or state
  )
end