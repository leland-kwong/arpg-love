
local definitions = {
  quest_1 = {
    title = 'The beginning',
    subTasks = {
      {
        id = 'quest_1_1',
        -- description = 'Take out **R-19 the Mad**'
        description = 'kill **5** **mini bots**',
        requirements = {
          killEnemy = {
            count = {
              ['ai-minibot'] = 5
            }
          }
        }
      },
    },
  },

  quest_2 = {
    title = 'Something lurking',
    subTasks = {
      {
        id = 'quest_2_1',
        description = 'Find and take out **R-19 the mad** in **Aureus**',
        requirements = {
          killEnemy = {
            count = {
              ['legendary-eyeball'] = 1
            }
          }
        }
      },
      {
        id = 'quest_2_2',
        description = 'Check back with **Lisa** at home',
        preRequisites = {
          'quest_2_1'
        },
        requirements = {
          npcInteract = {
            npcName = 'Lisa'
          }
        }
      }
    }
  }
}

return definitions