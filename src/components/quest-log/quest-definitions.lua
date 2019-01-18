
return {
  ['the-beginning'] = {
    title = 'The beginning',
    subTasks = {
      {
        id = 'the-beginning_1',
        -- description = 'Take out **R-19 the Mad**'
        description = 'kill 5 mini bots',
        requirements = {
          killEnemy = {
            count = {
              ['ai-minibot'] = 5
            }
          }
        }
      },
      -- {
      --   id = 'the-beginning_2',
      --   description = 'Bring his **brain** to **Lisa**',
      -- }
    },
    script = {
      text = "Hi [characterName], there is an evil robot who goes by the name of **R1 the mad**."
        .." Find him in **Aureus**, take him out, and retrieve his **brain**.",
      defaultOption = 'closeChat',
      options = {
        {
          label = "Got it.",
          action = 'acceptQuest'
        },
        {
          label = "I'm too scared, I'll pass on it this time.",
          action = 'rejectQuest'
        }
      }
    }
  },

  -- ['boss-1'] = {
  --   title = 'Something lurking',
  --   subTasks = {
  --     {
  --       id = 'boss-1_1',
  --       description = 'Find **Erion** in **Aureus floor 2**'
  --     },
  --     {
  --       id = 'boss-1_2',
  --       description = 'Take him out'
  --     }
  --   },
  --   script = {
  --     text = 'I feel something shaking up a storm deep under Aureus. You should check it out.',
  --     defaultOption = 'closeChat',
  --     options = {
  --       {
  --         label = "Got it.",
  --         action = 'acceptQuest'
  --       },
  --       {
  --         label = "I'm too scared, I'll pass on it this time.",
  --         action = 'rejectQuest'
  --       }
  --     }
  --   }
  -- }
}