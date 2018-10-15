local globalState = require 'main.global-state'
local msgBus = require 'components.msg-bus'
local Sound = require 'components.sound'
local HomeScene = require 'scene.sandbox.main-game.main-game-home'
local tick = require 'utils.tick'
local userSettings = require 'config.config'.userSettings

local bgMusic = {
  songQueue = nil,
  currentlyPlaying = nil,
  getEnabled = function()
    return userSettings.sound.musicEnabled
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
  if (not bgMusic.getEnabled()) then
    consoleLog('stop song', os.clock())
    stopSong()
    return
  end

  local Component = require 'modules.component'
  local sceneBluePrint = Component.getBlueprint(sceneRef)
  local song = songsByScene[sceneBluePrint]()
  local isSameSong = song == bgMusic.currentlyPlaying
  if isSameSong then
    return
  end
  stopSong()
  bgMusic.currentlyPlaying = song
  consoleLog('play song', os.clock())
  love.audio.play(song)

  local duration = 5
  -- local duration = song:getDuration('seconds')
  bgMusic.songQueue = tick.delay(function()
    bgMusic.currentlyPlaying = nil
    setSong(sceneRef)
  end, duration)
end

msgBus.MUSIC_TOGGLE = 'MUSIC_TOGGLE'
msgBus.on(msgBus.MUSIC_TOGGLE, function()
  userSettings.sound.musicEnabled = not userSettings.sound.musicEnabled
  local sceneRef = userSettings.sound.musicEnabled and globalState.activeScene or nil
  setSong(sceneRef)
  setVolume(userSettings.sound.musicVolume)
end)

msgBus.MUSIC_SET_VOLUME = 'MUSIC_SET_VOLUME'
msgBus.on(msgBus.MUSIC_SET_VOLUME, function(volume)
  userSettings.sound.musicVolume = volume
  setVolume(volume)
end)

msgBus.MUSIC_PLAY = 'MUSIC_PLAY'
msgBus.on(msgBus.MUSIC_PLAY, function(sceneRef)
  setSong(sceneRef)
  setVolume(userSettings.sound.musicVolume)
end)

msgBus.MUSIC_STOP = 'MUSIC_STOP'
msgBus.on(msgBus.MUSIC_STOP, function(sceneRef)
  setSong(sceneRef)
end)

msgBus.on(msgBus.KEY_DOWN, function (v)
  local config = require 'config.config'
  local keyMap = config.userSettings.keyboard
  if keyMap.MUSIC_TOGGLE == v.key then
    msgBus.send(msgBus.MUSIC_TOGGLE)
  end
end)
