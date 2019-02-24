return {
  something_lurking = {
    { text = 'There is something lurking underneath here...' },
    {
      text = 'What do you think we should do?',
      options = {
        {
          label = 'explore Aureus',
          actions = {
            {
              action = 'nextConversation',
              data = {
                id = 'something_lurking_finished'
              }
            },
          }
        },
        {
          label = 'I`ll be back',
          actions = {
            {
              action = 'nextConversation',
              data = {
                id = 'cancel'
              }
            }
          }
        }
      }
    },
  },
  something_lurking_finished = {
    {
      actionOnly = true,
      actions = {
        {
          action = 'giveReward',
          data = {
            experience = 100
          }
        }
      }
    },
    { text = 'Nice job on cleaning things up. Heres something that you might find useful.' }
  },
  cancel = {
    { actionOnly = true }
  }
}