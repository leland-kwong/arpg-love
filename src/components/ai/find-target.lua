local Component = require 'modules.component'

return {
  player = function()
    if Component.get('PLAYER_LOSE') then
      return nil
    end
    return Component.get('PLAYER')
  end
}