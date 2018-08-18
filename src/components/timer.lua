local Component = require'modules.component'
local groups = require'components.groups'
local tick = require'utils.tick'

local timerFactory = Component.createFactory({
	group = groups.all,
	fn = require'utils.noop',
	delay = 0,
	init = function(self)
		self.timeElapsed = 0
		self.timer = tick.delay(self.fn, self.delay / 1000)
	end,
	update = function(self, dt)
		self.timeElapsed = self.timeElapsed + dt
		tick.update(dt)
		if self.timeElapsed == self.delay then
			return self:delete()
		end
	end
})

return timerFactory