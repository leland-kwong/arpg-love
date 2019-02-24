local Component = require 'modules.component'

Component.create({
  id = 'ComponentSystemQueueDebug',
  x = 5,
  y = 40,
  init = function(self)
    Component.addToGroup(self, 'system')
    Component.debug.drawQueueStats = true
    local GuiText = require 'components.gui.gui-text'
    self.text = GuiText.create({
      font = require 'components.font'.primaryLarge.font,
      group = 'system'
    }):setParent(self)
  end,
  draw = function(self)
    local stats = Component.groups.drawQueueStats.getAll()
    local row = 0
    local F = require 'utils.functional'
    local rowMargin = 5
    local rowHeight = 53
    local barHeightMax = 30 - 10
    local barMargin = 1
    local chartWidth = 50
    for name,data in pairs(stats) do
      local round = require 'utils.math'.round
      local curLength = data.history:getNewest()
      local items = data.history:get()
      if #items > 0 and round(data.avgLength) ~= curLength then
        local dataSize = data.history.size
        local barWidth = math.ceil(chartWidth/dataSize)

        local Color = require 'modules.color'
        self.text:add(name, Color.WHITE, self.x, self.y + row * rowHeight)
        local _, textHeight = self.text:getSize()
        self.text:add(data.maxLength..' max', Color.YELLOW, self.x + (dataSize * (barWidth + barMargin)) + 4, self.y + row * rowHeight - ((textHeight-6)*2))
        self.text:add(string.format('%1.0f', data.avgLength)..' avg', Color.WHITE, self.x + (dataSize * (barWidth + barMargin)) + 4, self.y + row * rowHeight - (textHeight-6))
        self.text:add(curLength..' cur', Color.LIME, self.x + (dataSize * (barWidth + barMargin)) + 4, self.y + row * rowHeight)

        for i=1, #items do
          local len = items[i]
          local percentIncrease = math.max(0, (len/data.avgLength - 1))

          love.graphics.setColor(1,1,1)
          love.graphics.rectangle('fill', self.x + ((i-1)*barWidth+(i*barMargin)), self.y + (row * rowHeight), barWidth, -math.min(barHeightMax, math.ceil(percentIncrease * barHeightMax)))
        end
        row = row + 1
      end
    end
  end
})