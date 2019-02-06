local globalState = require 'main.global-state'

return {
  setBackgroundColor = function(color)
    globalState.backgroundColor = color
  end,
  updateGameClock = function(dt)
    globalState.gameClock = globalState.gameClock + dt
  end,
  setNewGameState = function(nextGameState)
    local CreateStore = require 'components.state.state'
    globalState.gameState = CreateStore(nextGameState)
  end,
  setActiveLevel = function(level)
    globalState.activeLevel = level
  end,
  setSceneTitle = function(title)
    globalState.sceneTitle = title or ''
  end
}