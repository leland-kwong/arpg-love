local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'
local GuiDialog = dynamicRequire 'components.gui.gui-dialog'
local GlobalState = require 'main.global-state'
local msgBus = require 'components.msg-bus'
local Md = dynamicRequire 'modules.markdown-to-love2d-string'
dynamicRequire 'components.map-text'

local function testQuests()
  local QuestLog = dynamicRequire 'components.hud.quest-log'
  local camera = require 'components.camera'
  local cameraWidth = camera:getSize()
  local uiWidth = 160
  local offset = 15
  QuestLog.create({
    id = 'QuestLog',
    x = cameraWidth - uiWidth - offset,
    y = 100,
    width = uiWidth,
    height = 200,
  })

  for i=1, 5 do
    local quest = {
      id = i,
      title = 'R1 the Mad #'..i,
      subTasks = {
        {
          id = i..'-1',
          description = 'Look for him in **Aureus**',
          completed = false
        },
        {
          id = i..'-2',
          description = 'Take him out',
          completed = false
        },
        {
          id = i..'-3',
          description = 'Return his brain to **Lisa**',
          completed = false
        }
      }
    }
    msgBus.send('QUEST_NEW', quest)
  end

  msgBus.send('QUEST_NEW', {
    id = 'hiddenTreasure',
    title = 'Hidden treasure',
    subTasks = {
      {
        id = 'hiddenTreasure-1',
        description = 'Find the treasure hidden beneath the ruins **south** of **Aureus**',
        completed = false
      },
      {
        id = 'hiddenTreasure-2',
        description = 'Find the treasure hidden beneath the ruins **south** of **Aureus**',
        completed = false
      }
    }
  })

  msgBus.send('QUEST_TASK_COMPLETE', {
    questId = 1,
    taskId = '1-1'
  })
  msgBus.send('QUEST_TASK_COMPLETE', {
    questId = 1,
    taskId = '1-2'
  })
  msgBus.send('QUEST_TASK_COMPLETE', {
    questId = 1,
    taskId = '1-3'
  })

  msgBus.send('QUEST_TASK_COMPLETE', {
    questId = 2,
    taskId = '2-1'
  })
end

local Quests = {
  ['1-1'] = {
    title = 'The Menace',
    description = 'Find and kill *R-1 the Mad* in *Aureus-floor-2*',
    condition = function()

    end
  }
}

local function drawShadow(self, sx, sy, ox, oy)
  local sh = select(3, self.animation.sprite:getViewport())
  local ox, oy = self.animation:getSourceOffset()
  -- SHADOW
  love.graphics.setColor(0,0,0,0.25)
  self.animation:draw(
    self.x,
    self.y + sh/2,
    0,
    sx,
    -1/4,
    ox,
    oy
  )
end

local function makeDialog(self)
  local gameState = msgBus.send('GAME_STATE_GET'):get()
  local characterName = gameState.characterName or ''
  local textPosition = {
    x = self.x + 12,
    y = self.y
  }

  local nextScript = coroutine.wrap(function()
    local nextScript
    local actions = {}

    actions.acceptQuest = function()
      local time = os.time()
      -- add new quest to log
      msgBus.send('QUEST_NEW', {
        id = 'quest #'..time,
        title = 'The beginning '..time,
        subTasks = {
          {
            id = 'the-beginning_1',
            description = 'Take out **R1 the Mad**'
          },
          {
            id = 'the-beginning_2',
            description = 'Bring his **brain** to **Lisa**'
          }
        }
      })

      nextScript = nil
    end

    actions.rejectQuest = function()
      nextScript = nil
    end

    nextScript = {
      text = "Hi "..characterName..", there is an evil robot who goes by the name of **R1 the mad**."
        .." Find him in **Aureus**, take him out, and retrieve his **brain**.",
      defaultOption = function()
        nextScript = nil
      end,
      options = {
        {
          label = "Got it.",
          action = actions.acceptQuest
        },
        {
          label = "I'm too scared, I'll pass on it this time.",
          action = actions.rejectQuest
        }
      }
    }

    while true do
      coroutine.yield(nextScript)
    end
  end)

  self.dialog = GuiDialog.create({
    id = 'QuestMasterSpeechBubble',
    renderPosition = textPosition,
    nextScript = nextScript
  }):setParent(self)
end

local Npc = Component.createFactory({
  name = 'Npc name',
  init = function(self)
    local parent = self
    Component.addToGroup(self, 'all')
    Component.addToGroup(self, 'npcs')

    self.animation = AnimationFactory:new({
      'npc-quest-master/character-8',
      'npc-quest-master/character-9',
      'npc-quest-master/character-10',
      'npc-quest-master/character-11'
    }):setDuration(1.25)

    local Gui = require 'components.gui.gui'
    local width, height = self.animation:getWidth(), self.animation:getHeight()
    local nameHeight = 12
    self.interactNode = Gui.create({
      group = 'all',
      width = width,
      height = height + nameHeight,
      onUpdate = function(self)
        self.x = parent.x - width/2
        self.y = parent.y - height/2 - nameHeight

        local msgBus = require 'components.msg-bus'
        local isInDialogue = (parent.canInteract and self.hovered) or
          (parent.dialog and (not parent.dialog:isDeleted()))
        msgBus.send('CURSOR_SET', {
          type = isInDialogue and 'speech' or 'default'
        })

        parent.canInteract = msgBus.send('INTERACT_ENVIRONMENT_OBJECT', self)
      end,
      getMousePosition = function()
        local camera = require 'components.camera'
        return camera:getMousePosition()
      end,
      onClick = function()
        if parent.canInteract then
          makeDialog(parent)
        end
      end
    }):setParent(parent)
  end,
  update = function(self, dt)
    self.animation:update(dt)

    local config = require 'config.config'
    local gs = config.gridSize

    local lightWorld = Component.get('lightWorld')
    lightWorld:addLight(self.x, self.y, 20)

    if self.canInteract then
      Component.addToGroup(
        Component.newId(),
        'interactableIndicators', {
          icon = 'cursor-speech',
          -- orientation =
          x = self.x + self.interactNode.w,
          y = self.y - 4
        }
      )
    end
  end,
  draw = function(self)
    drawShadow(self, 1, 1)

    Component.addToGroup(
      Component.newId(),
      'mapText',
      {
        text = self.name,
        x = self.interactNode.x + self.interactNode.width/2,
        y = self.interactNode.y,
        align = 'center'
      }
    )

    local Shaders = require 'modules.shaders'
    local shader = Shaders('pixel-outline.fsh')

    if self.interactNode.hovered then
      local atlasData = AnimationFactory.atlasData
      love.graphics.setShader(shader)
      shader:send('sprite_size', {atlasData.meta.size.w, atlasData.meta.size.h})
      shader:send('outline_width', 1)
      local Color = require 'modules.color'
      shader:send('outline_color', Color.YELLOW)
    end

    love.graphics.setColor(1,1,1)
    self.animation:draw(self.x, self.y)

    shader:send('outline_width', 0)
  end
})

Component.create({
  id = 'QuestMasterExample',
  group = 'all',
  init = function(self)
    Npc.create({
      id = 'QuestMaster',
      name = 'Lisa',
      x = 450,
      y = 350
    }):setParent(self)

    testQuests()
  end,
  update = function(self)
  end
})