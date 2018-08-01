# Thoughts - a place for quickly jotting down ideas

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