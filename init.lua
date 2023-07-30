local GameSession = require('GameSession')
local Cron = require('Cron')

local userState = {
    panam = {{""}},
    judy = {{""}}
}

registerForEvent('onInit', function()
    GameSession.StoreInDir('sessions') -- Set directory to store session data
    GameSession.Persist(userState) -- Link the data that should be watched and persisted 

    -- Whenever we load into the game, get the chat history accordingly and send out a custom primer for this history.
    GameSession.OnLoad(function()
        -- For each chat id, create a flat in the games' internal database
        -- Cyberchat gets these values and lists available chats accordingly
        TweakDB:SetFlat("CyberChat.Panam_handle", "@panam")
        TweakDB:SetFlat("CyberChat.Judy_handle", "@judy")

        -- According to our logic so far, since we send out a prime by ourself, we have to flush the CyberAI chat inbetween sessions:
        FlushChat("@panam")
        FlushChat("@judy")

        -- Here we handle this logic on our own, by sending out a primer. Notice that this is only slightly less efficient than before.
        for k,v in pairs(userState) do
            --print('for ' .. k .. ' length: ' .. #v)
            if #v < 2 then
                -- If there is no chatHistory for this key in this session
                print('[CyberChat-ext] There is no chat history for ' .. k .. ', wait for user initiation..')
            else
                -- If instead we have a chatHistory for this key in this session
                print('[CyberChat-ext] Dispatching chat history primer for ' .. k)
                table.insert(userState[k], {"System","(The user is back online, act suprised, glad or sarcastic)"})
                ScheduleChatCompletionRequest("@" .. k, v)
            end
        end

        --[[
        if #userState.chatHistory < 2 then
            -- If there is no chatHistory for this session (or id..)
            print('[CyberChat-ext] There is no chat history, wait for user initiation..')
         else
              -- If we have a chatHistory for this session (and id...)
              print('[CyberChat-ext] Dispatching chat history primer..')
              table.insert(userState.chatHistory, {"System","(The user is back online, act suprised, glad or sarcastic)"})
              ScheduleChatCompletionRequest("@panam", userState.chatHistory)
        end
        ]]--
    end)

    -- This saves the full chat interaction locally every 10 seconds.
    Cron.Every(10.0, { tick = 1 }, function(timer)
        -- At this time, we need to manually list possible handles to be persisted.
        -- This could be made so arbitrary handles are supported in the future. But would that make sense? For open-world NPCs maybe
        userState.panam = GetHistory("@panam")
        userState.judy = GetHistory("@judy")
        print(('[CyberChat-ext] [%s] Every %.2f secs: Chat(s) saved.'):format(os.date('%H:%M:%S'), timer.interval))
    end)
end)

registerForEvent('onUpdate', function(delta)
    -- This is required for Cron to function
    Cron.Update(delta)
end)