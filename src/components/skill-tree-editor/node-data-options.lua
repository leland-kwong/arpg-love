local Component = require 'modules.component'
local MenuList = require 'components.menu-list'
local F = require 'utils.functional'
local config = require 'config.config'

local NodeDataOptions = {
  options = {},
  onSelect = function(name, value)
  end
}

function NodeDataOptions.init(self)
  local root = self
  Component.addToGroup(self, 'gui')

  local keys = F.keys(self.options)
  local menuOptions = F.map(keys, function(key)
    return {
      name = self.options[key].name,
      value = key,
      onSelectSoundEnabled = false
    }
  end)
  self.menu = MenuList.create({
    x = self.x / config.scale,
    y = self.y / config.scale,
    width = 200,
    options = menuOptions,
    onSelect = self.onSelect,
    drawOrder = function()
      return root:drawOrder() + 1
    end
  }):setParent(self)
end

function NodeDataOptions.draw(self)
  local drawBox = require 'components.gui.utils.draw-box'
  drawBox(self.menu)
end

function NodeDataOptions.drawOrder()
  return 11
end

return Component.createFactory(NodeDataOptions)