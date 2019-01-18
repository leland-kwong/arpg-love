
return {
  ['the-beginning'] = {
    title = 'The beginning',
    subTasks = {
      {
        id = 'the-beginning_1',
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

  ['boss-1'] = {
    title = 'Something lurking',
    subTasks = {
      {
        id = 'boss-1_1',
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
        id = 'boss-1_2',
        description = 'Collect **5** **scrap metal** pieces',
        requirements = {
          killEnemy = {
            count = {
              ['legendary-eyeball'] = 1
            }
          }
        }
      }
    },
    script = {
      text = 'I feel something shaking up a storm deep under Aureus. You should check it out.',
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
  }
}