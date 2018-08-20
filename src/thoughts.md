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
- UNEQUIP_ITEM
- PLAYER_MOVE
- PLAYER_IDLE
- PLAYER_ATTACK
- PLAYER_ADD_HEAL_SOURCE_RECEIVED
- PLAYER_AURA_TRIGGER
- ENEMY_ATTACK
- ENEMY_DESTROYED

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