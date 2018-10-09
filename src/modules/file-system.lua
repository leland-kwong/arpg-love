local f = require 'utils.functional'
local bitser = require 'modules.bitser'

local fileSystem = {}

local SAVED_GAMES_LIST = 'saved-games-list'
local errorFree, savedGames = pcall(function()
  return bitser.loadLoveFile(SAVED_GAMES_LIST)
end)
savedGames = (errorFree and savedGames) or {}

local function saveSavedGamesList()
  bitser.dumpLoveFile(SAVED_GAMES_LIST, savedGames)
end

local function updateSavedGamesList(fileName, metadata)
  if savedGames[fileName] then
    return
  end
  savedGames[fileName] = metadata
  saveSavedGamesList()
end

local bitser = require 'modules.bitser'
function fileSystem.saveFile(fileName, data, metadata)
  updateSavedGamesList(fileName, metadata)
  bitser.dumpLoveFile(
    fileName,
    data
  )
end

function fileSystem.loadSaveFile(fileName)
  local errorFree, loadedState = pcall(function()
    return bitser.loadLoveFile(fileName)
  end)
  return loadedState
end

function fileSystem.deleteSaveFile(fileName)
  savedGames[fileName] = nil
  saveSavedGamesList()
end

function fileSystem.listSavedFiles()
  return f.map(f.keys(savedGames), function(fileName)
    return {
      id = fileName,
      metadata = savedGames[fileName]
    }
  end)
end

return fileSystem