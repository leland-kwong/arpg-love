local Component = require 'modules.component'
local Font = require 'components.font'
local Color = require 'modules.color'
local Position = require 'utils.position'
local GuiText = require 'components.gui.gui-text'
local camera = require 'components.camera'
local pixelTextOutline = require 'modules.shaders.pixel-text-outline'
local msgBus = require 'components.msg-bus'

local PlayerLose = {
  id = 'PLAYER_LOSE'
}

local vignette = love.graphics.newImage('built/images/vignette2.png')

local restartEvents = {
  [msgBus.KEY_PRESSED] = true,
  [msgBus.MOUSE_CLICKED] = true
}

function PlayerLose.init(self)
  Component.addToGroup(self:getId(), 'hud', self)
  msgBus.on('*', function(_, msgType)
    if restartEvents[msgType] then
      local HomeBase = require 'scene.home-base'
      msgBus.send(msgBus.SCENE_STACK_PUSH, {
        scene = HomeBase
      })
      self:delete(true)
      return msgBus.CLEANUP
    end
  end)
end

function PlayerLose.draw(self)
  local gfx = love.graphics
  local titleFont = Font.secondaryLarge.font
  local camW, camH = camera:getSize()

  gfx.setColor(0,0,0,0.2)
  gfx.rectangle('fill', 0, 0, camW, camH)

  gfx.setColor(0,0,0,1)
  gfx.draw(vignette)
  gfx.draw(vignette)


  gfx.setFont(titleFont)
  gfx.setColor(Color.DEEP_RED)
  pixelTextOutline.attach()

  local text = 'You have perished.'
  local titleW, titleH = GuiText.getTextSize(text, titleFont)
  local centerX, centerY = Position.boxCenterOffset(titleW, titleH, camW, camH)
  gfx.print(text, centerX, centerY)


  local bodyFont = Font.primary.font
  gfx.setFont(bodyFont)
  gfx.setColor(Color.YELLOW)
  local text = 'press any key to continue'
  local bodyW, bodyH = GuiText.getTextSize(text, bodyFont)
  local centerX = Position.boxCenterOffset(bodyW, bodyH, camW, camH)
  gfx.print(text, centerX, centerY + titleH + 5)

  pixelTextOutline.detach()
end

return Component.createFactory(PlayerLose)