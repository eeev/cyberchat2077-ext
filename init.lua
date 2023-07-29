local GameSession = require('GameSession')
local Cron = require('Cron')

local userState = {
    chatHistory = {{""}}
}

registerForEvent('onInit', function()
    GameSession.StoreInDir('sessions') -- Set directory to store session data
    GameSession.Persist(userState) -- Link the data that should be watched and persisted 

    -- Whenever we load into the game, get the chat history accordingly and send out a custom primer for this history.
    GameSession.OnLoad(function()
        -- According to our logic so far, since we send out a prime by ourself, we have to flush the CyberAI chat inbetween sessions:
        FlushChat("@panam")

        -- Here we handle this logic on our own, by sending out a primer. Notice that this is only slightly less efficient than before.
        if #userState.chatHistory < 2 then
           -- If there is no chatHistory for this session (or id..)
           print('[CyberChat-ext] There is no chat history, wait for user initiation..')
        else
             -- If we have a chatHistory for this session (and id...)
             print('[CyberChat-ext] Dispatching chat history primer..')
             table.insert(userState.chatHistory, {"System","(The user is back online, act suprised, glad or sarcastic)"})
             ScheduleChatCompletionRequest("@panam", userState.chatHistory)
        end
    end)

    -- This saves the full chat interaction locally every 10 seconds.
    Cron.Every(10.0, { tick = 1 }, function(timer)
        userState.chatHistory = GetHistory("@panam")
        print(('[CyberChat-ext] [%s] Every %.2f secs: Chat saved.'):format(os.date('%H:%M:%S'), timer.interval))
    end)
end)

registerForEvent('onUpdate', function(delta)
    -- This is required for Cron to function
    Cron.Update(delta)
end)