local Component = require 'modules.component'

return Component.createFactory({
  mainMenu = false,
  init = function(self)
    local msgBus = require 'components.msg-bus'
    msgBus.send(msgBus.TOGGLE_MAIN_MENU, self.mainMenu)
  end
})