local globalState = require 'main.global-state'
local msgBus = require 'components.msg-bus'
local Sound = require 'components.sound'
local HomeScene = require 'scene.sandbox.main-game.home-screen'
local tick = require 'utils.tick'
local userSettings = require 'config.user-settings'
local userSettingsState = require 'config.user-settings.state'

local bgMusic = {
  songQueue = nil,
  currentlyPlaying = nil,
  getEnabled = function()
    return userSettings.sound.musicVolume > 0
  end
}

local songsByScene = setmetatable({
  [HomeScene] = function()
    return Sound.music.homeScreen
  end,
}, {
  __index = function()
    return function()
      return Sound.music.mainGame
    end
  end
})

local function setVolume(volume)
  if bgMusic.currentlyPlaying then
    bgMusic.currentlyPlaying:setVolume(volume)
  end
end

local function updateAllVolumes()
  setVolume(userSettings.sound.musicVolume)
  love.audio.setVolume(userSettings.sound.masterVolume)
end

local function stopSong()
  if bgMusic.currentlyPlaying then
    love.audio.stop(bgMusic.currentlyPlaying)
  end
  if bgMusic.songQueue then
    bgMusic.songQueue:stop()
  end
  bgMusic.currentlyPlaying = false
end

-- song manager entry point. Handles playing/stopping based on states
local function setSong(sceneRef)
  local Component = require 'modules.component'
  local sceneBluePrint = Component.getBlueprint(sceneRef)
  local song = songsByScene[sceneBluePrint]()
  local isSameSong = song == bgMusic.currentlyPlaying
  if isSameSong then
    return
  end
  stopSong()
  bgMusic.currentlyPlaying = song
  updateAllVolumes()
  love.audio.play(song)

  local duration = 5
  -- local duration = song:getDuration('seconds')
  bgMusic.songQueue = tick.delay(function()
    bgMusic.currentlyPlaying = nil
    setSong(sceneRef)
  end, duration)
end

msgBus.on(msgBus.MUSIC_PLAY, function(sceneRef)
  setSong(sceneRef)
end)

msgBus.on(msgBus.MUSIC_STOP, function(sceneRef)
  setSong(sceneRef)
end)

msgBus.on(msgBus.KEY_DOWN, function (v)
  local config = require 'config.config'
  local keyMap = userSettings.keyboard
  if keyMap.MUSIC_TOGGLE == v.key then
    msgBus.send(msgBus.MUSIC_TOGGLE)
  end
end)

msgBus.on(msgBus.UPDATE, updateAllVolumes)
