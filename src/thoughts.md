# Thoughts - a place for quickly jotting down ideas

## 2-d game engines

- love2d (lua)
- game maker studio 2 (gml)
- godot (c#, gdnative)
- pygame (python)
- unity (c#)
- monogame (c#)

## Ai movement

If collision is detected, offset the endpoint by the collision normal.

## Continuous Effects on player

- aura
- passive
- curse
- buff
- debuff

Each spell, item, trap, etc, calls `msgBus.send(msgType, msgValue)` on their own. If an effect also affects an enemy, the effect should cast its own collision object and manage those events separately (deal damage, slow movement...).

### Effects trigger on the following events

- player state change
- player hit received
- player item is equipped
- player healed
- enemy hit received

Whenever an event occurs, it sends that information to the event bus. Each event in the event bus gets run through a series of reducers and the final value is then sent as a message to the appropriate receivers (game objects).

## Message types

- EQUIPMENT_CHANGE
- EQUIPMENT_UNEQUIP
- PLAYER_MOVE
- PLAYER_IDLE
- PLAYER_ATTACK
- PLAYER_ADD_HEAL_SOURCE_RECEIVED
- PLAYER_AURA_TRIGGER
- ENEMY_ATTACK
- ENTITY_DESTROYED

## Static vs dynamic modifiers

**Static modifiers** are applied once and never change.

**Dynamic modifiers** are applied in response to a message and modify and transform the message output as necessary.

## GUI code architecture

- [x] gui component generates a hitbox with hover, click, onChange handlers
- [x] we do the rendering separately in the `render` method

## Experience calculation

currentLevelExp = (totalExp - currentLevelRequirement)
expRequiredForLevelUp = nextLevelRequirement - currentLevelRequirement
progress = currentLevelExp / expRequiredForLevelUp

## Scene selection menu

- [x] gui button to open up scene selection menu
- [x] load previously selected scene from disk
- [x] persist selected scene to disk so we can reload last selected scene
- [x] if no scene is selected, show menu
- [x] cleanup scene before loading a new scene

## Stat modifier calculation

stat = baseStat + (baseState * percentModier) + flatModifier

### Base stats

- speed (movement speed)
- armor (percent damage reduction)
- health
- maxHealth
- healthRegeneration
- damage
- resistances (fire, cold, lightning, poision, etc...)
- sightRadius
- attackRange

### Status effects

- silenced
- stun (could be implemented with `silence` and `speed = 0`)

### Modifiable stats

- speed
- armor
- maxHealth
- healthRegeneration
- damage
- resistances
- sightRadius
- attackRange

## Socketables

### Multi attack (weapons)

(ranged) Projectiles split into 3, each projectile dealing 33% damage
(melee) Melee attacks do 2 quick attacks in succession

### Reduced energy cost (weapons)

Reduces energy cost of the weapon

### Faster energy regeneration (armor only)

Increases player's energy regeneration

### Reduced physical damage (armor only)

Reduces physical damage taken by player

## Loot chances

1. Roll chance for dropping an item
2. Roll chance for rarity of item drop
3. Roll chance for item in pool based on rarity

## Loot file structure

All of the following should have a unique id (hashed name) associated with them so we can easily look them via a hash table.

- base item types
- prefix modifiers (shocking, flaming, midndful, etc...)
- suffix modifiers (of the bear, of flight, etc...)
- upgrades (modifiers that are gained after a certain amount of experience has been earned)
- epic items that sub-class base item types
- legendary items that sub-class base item types
- consumable active methods
- equipment active methods

### Item data structure

#### base item type data structure

```lua
local item = {
  type = '', -- unique type for the item (hashed for saving and loading)

  instanceProps =  {
    props = {}, -- item-specific props for use with active abilities

    baseModifiers = {
      -- instance-level base modifiers
      armor =                         {0, 1}, -- min-max range to roll with
      percentDamage =                 {0, 1}, -- percent damage increase to all damage types
      flatDamage =                    {0, 1}, -- flat physical increase
      weaponDamage =                  {0, 1},
      moveSpeed =                     {0, 0},
      healthRegen =                   {0, 1},
      maxHealth =                     {0, 1},
      energyRegen =                   {0, 1},
      maxEnergy =                     {0, 1},
      lightningResist =               {0, 1},
      fireResist =                    {0, 1},
      coldResist =                    {0, 1},
      attackTime =                    {0, 0},
      energyCost =                    {0, 0},
      flatPhysicalDamageReduced =     {0, 1},
      attackTimeReduced =             {0, 1},  -- percent attack time reduction
      cooldownReduced =               {0, 1},  -- percent cooldown reduction
      energyCostReduced =             {0, 1},  -- percent energy cost reduction
      extraExperience =               {0, 1}   -- percent extra experience
    },

    extraModifiers = {}, -- additional instance-level properties: upgrades, and modifiers from magicals, rares, legendaries... These modifiers are calculated on-top of the baseModifiers
    rarity = 1, -- defaults to NORMAL

    stackSize = 1, -- defaults to 1 (not stackable)
    maxStackSize = 1, -- defaults to 1

    onActivate = require 'inventory-active-method', -- active ability when right-clicked inside inventory. For equipment it swaps it with the compatible equipment slot. For consumables it will activate the item.

    onActivateWhenEquipped = require 'equipped-active-method', -- active ability when the item is equipped. The ability appears in the hot bar.
  },

  -- static item properties (these properties should only change if code has changed)
  properties = {
    title = '', -- unique title for the item
    sprite = '', -- name of sprite to render when inside inventory
    levelRequirement = 1,
    renderAnimation = '', -- name of sprite to render when equipped
    experience = 0, -- experience earned while this item was equipped
    category = 1, -- type of item: "consumable", "weapon", "armor", ...
  }
}
```

#### module data structure

```lua
local module = {
  type = '', -- unique type (hashed for saving and loading)
  active = function(item) -- for items with an active ability
  end,
  tooltip = function(item) -- every module must have a tooltip
    return '' or {} -- love formatted string
  end
}
```

#### modifier data structure

```lua
-- [modifier props]
-- These are modifier instance level props generated upon item creation
{
  experienceRequired = 0, -- all modifiers have a default experience requirement of 0
}

-- modifier blueprint
{
  name = '', -- unique modifier name (we lookup the file based on this)
  type = '', -- unique type (we lookup the file based on this)
  displayTitle = '', -- title to display for gui
}
```

## Equipment system

1. Item equipped -> add item to equipment system
2. Item activate -> add ability entity to ability system
3. Add ability to upgrade system

## Credits

Ootsby - boids ai improvement
Lumie1337 - item range calculation
