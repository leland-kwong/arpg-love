local Component = require 'modules.component'

return Component.createFactory({
  mainMenu = false,
  init = function(self)
    local msgBusMainMenu = require 'components.msg-bus-main-menu'
    msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, self.mainMenu)
  end
})