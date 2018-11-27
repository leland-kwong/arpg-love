local config = require 'config.config'

if config.isDevelopment then
  return {
    equipment = {
      'base.potion-health',
      'base.pod-module-initiate',
      'base.pod-module-swipe',
      'base.potion-energy',
      'base.mock-shoes',
    },
    inventory = {
      'base.pod-module-hammer',
      'legendary.augmentation-module-frenzy',
      'legendary.defender-of-aureus',
      'base.augmentation-module-one',
    }
    -- {
    --   type = 'lightning-rod',
    --   position = {
    --     x = 1,
    --     y = 2
    --   }
    -- },
    -- {
    --   type = 'mock-armor',
    --   position = {
    --     x = 2,
    --     y = 3
    --   }
    -- },
    -- {
    --   type = 'pod-module-fireball'
    -- }
  }
else
  return {
    equipment = {
      'base.potion-health',
      'base.pod-module-initiate',
      'base.potion-energy',
      'base.augmentation-module-one',
      'base.mock-shoes'
    },
    inventory = {
    }
  }
end