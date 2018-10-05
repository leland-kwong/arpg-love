local Component = require 'modules.component'
local Color = require 'modules.color'
local font = require 'components.font'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local GuiText = require 'components.gui.gui-text'
local functional = require 'utils.functional'
local Lru = require 'utils.lru'

local FontTest = {
  group = Component.groups.system,
  clock = 0,
  files = {}
}

function FontTest.init(self)
  msgBus.send(msgBus.SET_BACKGROUND_COLOR, Color.LIGHT_GRAY)
  self.guiText = GuiText.create({
    font = font.primaryLarge.font
  })
end

local loadedFonts = Lru.new(100)
local baseDir = 'built/fonts'
local fontSize = 16

local function fileListReducer(basePath)
  return function(list, path)
    local isFontFile = string.find(path, '%.ttf') or string.find(path, '%.TTF')
    if isFontFile then
      local actualPath = basePath..'/'..path
      local cachePath = string.sub(path, 1, #path - 4)
      local loaded = loadedFonts:get(cachePath)
      if (not loaded) then
        local fontObject = love.graphics.newFont(actualPath, fontSize)
        loadedFonts:set(cachePath, fontObject)
      end
    else
      local isDirectory = not string.find(path, '%.')
      if isDirectory then
        local folder = baseDir..'/'..path
        return functional.reduce(love.filesystem.getDirectoryItems(folder), fileListReducer(folder), list)
      end
    end
    return list
  end
end

local pixelOutlineShader = love.filesystem.read('modules/shaders/pixel-outline.fsh')
local outlineColor = {0,0,0,1}
local shader = love.graphics.newShader(pixelOutlineShader)
local function setShader()
  local textW, textH = 16, 16
  shader:send('sprite_size', {textW, textH})
  shader:send('outline_width', 2/textW)
  shader:send('outline_color', outlineColor)
  shader:send('use_drawing_color', true)
  shader:send('include_corners', true)
  love.graphics.setShader(shader)
end

function FontTest.update(self, dt)
  self.clock = self.clock + 1
  if (self.clock % 10) == 0 then
    loadedFonts = Lru.new(100)
    self.files = functional.reduce(
      love.filesystem.getDirectoryItems(baseDir),
      fileListReducer(baseDir),
      {}
    )
  end
end

function FontTest.draw(self)
  love.graphics.push()
  love.graphics.scale(2)

  setShader()
  local output = {}
  local i = 0
  for k,fontObject in loadedFonts.pairs() do
    i = i + 1
    love.graphics.setFont(fontObject)
    love.graphics.print(k, 150, i * 24)
  end

  love.graphics.setShader()
  love.graphics.pop()
end

local Factory = Component.createFactory(FontTest)

msgBusMainMenu.send(msgBusMainMenu.MENU_ITEM_ADD, {
  name = 'font test',
  value = function()
    msgBus.send(msgBus.SCENE_STACK_PUSH, {
      scene = Factory
    })
  end
})