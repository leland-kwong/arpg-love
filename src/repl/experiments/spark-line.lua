local Component = require 'modules.component'
local F = require 'utils.functional'

Component.create({
  id = 'sparkLineExample',
  maxNumPoints = 50,
  init = function(self)
    Component.addToGroup(self, 'system')
    self.data = {}
    self.max = 0

    self.total = 0
    self.tally = 0

    self.clock = 0

  end,
  update = function(self, dt)
    self.clock = self.clock + dt
    local memUsage = collectgarbage('count')

    self.total = self.total + memUsage
    self.tally = self.tally + 1
    self.max = math.max(self.max, memUsage)

    if self.tally >= 100 then
      local avg = self.total/self.tally
      table.insert(self.data, 1, avg)
      self.total = 0
      self.tally = 0

      if #self.data > self.maxNumPoints then
        table.remove(self.data, #self.data)
      end
    end

    self.yAxisOffset = love.graphics.getHeight() - 20
    self.line = {}
    for i=1, #self.data do
      local v = self.data[i]
      local interval = 2
      table.insert(self.line, i * interval)
      table.insert(self.line, (-v/self.max * 20) + self.yAxisOffset)
    end
  end,
  draw = function(self)
    if #self.line >= 4 then
      love.graphics.setColor(1,1,1)
      love.graphics.line(self.line)
    end
    local font = require 'components.font'.primaryLarge.font
    love.graphics.setFont(font)
    love.graphics.print(math.floor(self.max) or '', 150, self.yAxisOffset - 20)
  end
})