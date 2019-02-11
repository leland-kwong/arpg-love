local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local GuiList = require 'components.gui.gui-list'
local Color = require 'modules.color'
local font = require 'components.font'
local msgBus = require 'components.msg-bus'
local f = require 'utils.functional'
local userSettings = require 'config.user-settings'
local userSettingsState = require 'config.user-settings.state'
local MenuManager = require 'modules.menu-manager'

local SettingsMenu = {}

function SettingsMenu.init(self)
  Component.addToGroup(self, 'gui')
  MenuManager.clearAll()
  MenuManager.push(self)

  local menuX, menuY = self.x, self.y
  local menuWidth, menuHeight = self.width, self.height
  local menuPadding = 10
  local menuInnerX, menuInnerY = menuX + menuPadding, menuY + menuPadding

  local guiTextTitle = GuiText.create({
    group = Component.groups.gui,
    font = font.secondary.font,
    drawOrder = function()
      return 4
    end
  })

  local guiTextBody = GuiText.create({
    group = Component.groups.gui,
    font = font.primary.font,
    drawOrder = guiTextTitle.drawOrder
  })

  --[[
    option {
      label = STRING
      value = ANY
    }
  ]]
  local ToggleGroup = function(params)
    local position, options, onSelect =
      params.position, params.options, params.onSelect
    return Component.create({
      x = position.x,
      y = position.y - 3,
      h = 30,
      init = function(self)
        local parent = self
        self.state = {
          value = params.value
        }

        f.forEach(options, function(o, index)
          local w = 15
          local margin = (index - 1) * (params.margin or 2)
          Gui.create({
            w = w,
            onUpdate = function(self)
              self.x = parent.x + (w * (index - 1)) + margin
              self.y = parent.y

              guiTextBody:addf({Color.WHITE, o.label}, self.w, 'center', self.x, self.y + 3)
              local w,h = guiTextBody:getSize()
              self.h = h + 4
            end,
            onClick = function()
              onSelect(o.value)
              self.state.value = o.value
            end,
            render = function(self)
              if self.hovered then
                love.graphics.setColor(0,1,1,0.2)
                love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
              end
              if parent.state.value == o.value then
                love.graphics.setColor(0,1,1)
                love.graphics.rectangle('line', self.x, self.y, self.w, self.h)
              end
            end
          }):setParent(parent)
        end)
      end
    })
  end

  local graphicsSectionTitle = Component.create({
    x = menuInnerX,
    y = menuInnerY,
    init = function(self)
      Component.addToGroup(self, 'gui')
      guiTextTitle:add('GRAPHICS', Color.LIGHT_GRAY, self.x, self.y)
      self.w, self.h = guiTextTitle:getSize()
    end,
    update = function(self)
      guiTextTitle:add('GRAPHICS', Color.LIGHT_GRAY, self.x, self.y)
    end
  })

  local displayScaleToggleGroupLabel = Component.create({
    x = menuInnerX,
    y = graphicsSectionTitle.y + graphicsSectionTitle.h + 10,
    text = 'display scale',
    init = function(self)
      Component.addToGroup(self, 'gui')
      guiTextBody:add('display scale', Color.LIGHT_GRAY, self.x, self.y)
      self.w, self.h = guiTextBody:getSize()
    end,
    update = function(self)
      guiTextBody:add('display scale', Color.LIGHT_GRAY, self.x, self.y)
    end
  })
  local displayScaleToggleGroup = ToggleGroup({
    position = {
      x = displayScaleToggleGroupLabel.x + displayScaleToggleGroupLabel.w + 10,
      y = displayScaleToggleGroupLabel.y
    },
    value = userSettings.display.scale,
    options = {
      {
        label = 1,
        value = 1
      },
      {
        label = 2,
        value = 2
      },
      {
        label = 3,
        value = 3
      }
    },
    onSelect = function(displayScale)
      local originallScale = userSettings.display.scale
      userSettingsState.set(function(settings)
        settings.display.scale = displayScale
        return settings
      end):next(function()
        consoleLog(string.format('[settings] display scale changed from `%d` to `%d` !', originallScale, displayScale))
      end)
    end
  })

  local soundSectionTitle = Component.create({
    x = menuInnerX,
    y = displayScaleToggleGroup.y + 35,
    init = function(self)
      Component.addToGroup(self, 'gui')
    end,
    draw = function(self)
      guiTextTitle:add('SOUND', Color.LIGHT_GRAY, self.x, self.y)
    end
  })

  local list = GuiList.create({
    x = menuX,
    y = menuY,
    width = menuWidth,
    height = menuHeight,
    contentHeight = 550,
    drawOrder = function()
      return 1100
    end
  }):setParent(self)
  Component.addToGroup(list, 'guiDrawBox')

  local function sliderSoundAdjusted(volume)
    local source = love.audio.newSource('built/sounds/gui/volume-adjusted.wav', 'static')
    source:setVolume(volume)
    love.audio.play(source)
  end
  local GuiSlider = require 'components.gui.gui-slider'
  local musicSlider = GuiSlider.create({
    x = menuInnerX,
    y = soundSectionTitle.y + 40,
    width = 150,
    knobSize = 10,
    onChange = function(self)
      local newVolume = self:getCalculatedValue() / 100
      sliderSoundAdjusted(newVolume)
      userSettingsState.set(function(settings)
        settings.sound.musicVolume = newVolume
        return settings
      end):next(function()
        consoleLog('settings saved!')
      end)
    end,
    draw = function(self)
      local railHeight = self.railHeight
      -- slider rail
      love.graphics.setColor(0.4,0.4,0.4)
      love.graphics.rectangle('fill', self.x, self.y, self.width, railHeight)

      -- slider control
      if self.knob.hovered then
        love.graphics.setColor(0,1,0)
      else
        love.graphics.setColor(1,1,0)
      end
      local offsetX, offsetY = self.knob.w/2, self.knob.w/2
      love.graphics.circle('fill', self.knob.x + offsetX, self.knob.y + offsetY, self.knob.w/2)

      love.graphics.setColor(1,1,1)
      love.graphics.setFont(font.primary.font)
      local round = require 'utils.math'.round
      local displayValue = round(self:getCalculatedValue())
      guiTextBody:add('Music: '..displayValue, Color.WHITE, self.x, self.y - 15)
    end
  }):setCalculatedValue(userSettings.sound.musicVolume * 100)
  local soundSlider = GuiSlider.create({
    x = menuInnerX,
    y = musicSlider.y + 30,
    width = 150,
    knobSize = 10,
    onChange = function(self)
      local newVolume = self:getCalculatedValue() / 100
      sliderSoundAdjusted(newVolume)
      userSettingsState.set(function(settings)
        settings.sound.masterVolume = newVolume
        return settings
      end):next(function()
        consoleLog('settings saved')
      end)
    end,
    draw = function(self)
      local railHeight = self.railHeight
      -- slider rail
      love.graphics.setColor(0.4,0.4,0.4)
      love.graphics.rectangle('fill', self.x, self.y, self.width, railHeight)

      -- slider control
      if self.knob.hovered then
        love.graphics.setColor(0,1,0)
      else
        love.graphics.setColor(1,1,0)
      end
      local offsetX, offsetY = self.knob.w/2, self.knob.w/2
      love.graphics.circle('fill', self.knob.x + offsetX, self.knob.y + offsetY, self.knob.w/2)

      love.graphics.setColor(1,1,1)
      love.graphics.setFont(font.primary.font)
      local round = require 'utils.math'.round
      local displayValue = round(self:getCalculatedValue())
      guiTextBody:add('Master: '..displayValue, Color.WHITE, self.x, self.y - 15)
    end
  }):setCalculatedValue(userSettings.sound.masterVolume * 100)
  local childNodes = {
    graphicsSectionTitle,
    displayScaleToggleGroupLabel,
    displayScaleToggleGroup,
    soundSectionTitle,
    musicSlider,
    soundSlider
  }

  local hotkeySectionTitle = Component.create({
    x = menuInnerX,
    y = soundSlider.y + 35,
    init = function(self)
      Component.addToGroup(self, 'gui')
    end,
    draw = function(self)
      guiTextTitle:add('HOTKEYS', Color.LIGHT_GRAY, self.x, self.y)
    end
  })
  table.insert(childNodes, hotkeySectionTitle)
  local TemplateParser = require 'utils.string-template'
  local parser = TemplateParser({
    delimiters = {'{', '}'}
  })
  local function actionTypeHumanized(action)
    local index = 0
    return action.gsub(action, '[A-Z_]', function(char)
      local isFirstChar = index == 0
      index = index + 1
      if isFirstChar then
        return char
      end
      if (char == '_') then
        return ' '
      end
      return string.lower(char)
    end)
  end
  local userSettings = require 'config.user-settings'
  local actionNames = f.keys(userSettings.keyboard)
  table.sort(actionNames)
  childNodes = f.reduce(
    actionNames,
    function(guiNodes, actionType, index)
      local state = {
        changeEnabled = false
      }
      local isFixedAction = userSettings.keyboardFixedActions[actionType]
      local wrapLimit = 200
      local function changeHotKey(self, ev)
        love.audio.play(
          love.audio.newSource(
            'built/sounds/gui/UI_SCI-FI_Tone_Deep_Dry_05_stereo.wav',
            'static'
          )
        )
        state.changeEnabled = true
        msgBus.on(msgBus.KEY_DOWN, function(ev)
          userSettingsState.set(function(settings)
            settings.keyboard[actionType] = ev.key
            return settings
          end):next(function()
            consoleLog('settings saved!')
          end, function(err)
            print('settings save error')
          end)
          state.changeEnabled = false
          love.audio.play(
            love.audio.newSource(
              'built/sounds/gui/UI_SCI-FI_Tone_Deep_Dry_05_stereo - reverse.wav',
              'static'
            )
          )
          return msgBus.CLEANUP
        end)
      end
      local hotkeyNode = Gui.create({
        x = menuInnerX,
        y = hotkeySectionTitle.y + 30 + ((index - 1) * 20),
        onClick = ((not isFixedAction) and changeHotKey or nil),
        onUpdate = function(self)
          local template = '{action}: {key}'
          local data = {
            action = actionType,
            key = state.changeEnabled and 'press new key' or userSettings.keyboard[actionType]
          }
          local coloredText = {}
          local parsed = parser(template, data)
          for fragment,value in parsed do
            local isStringFragment = value == nil
            local displayValue = (not isStringFragment) and value or fragment
            if (not isStringFragment) and (fragment == 'action') then
              displayValue = actionTypeHumanized(value)
            end

            local color = (fragment == 'key') and (state.changeEnabled and Color.YELLOW or Color.LIME) or Color.WHITE
            if (fragment == 'key') and isFixedAction then
              color = Color.LIGHT_GRAY
            end

            table.insert(coloredText, color)
            table.insert(coloredText, displayValue)
          end
          self.coloredText = coloredText
          local textWidth, textHeight = GuiText.getTextSize(coloredText, guiTextBody.font, wrapLimit, 'left')
          self.padding = 2
          self.w, self.h = 100, textHeight + (self.padding * 2)
        end,
        draw = function(self)
          if self.hovered and (not state.changeEnabled) then
            love.graphics.setColor(1,1,0)
            love.graphics.rectangle('fill', self.x, self.y - self.padding, self.w, self.h)
          end
          guiTextBody:addf(self.coloredText, wrapLimit, 'left', self.x, self.y)
        end,
        drawOrder = function()
          return guiTextBody:drawOrder() - 1
        end
      })
      table.insert(guiNodes, hotkeyNode)
      return guiNodes
    end,
    childNodes
  )

  table.insert(childNodes, guiTextTitle)
  table.insert(childNodes, guiTextBody)
  list.childNodes = childNodes
end

function SettingsMenu.final(self)
  MenuManager.pop()
end

return Component.createFactory(SettingsMenu)