local GameSession = require('GameSession')
local Cron = require('Cron')

local chatState = {
    panam = {{""}},
    judy = {{""}},
    johnny = {{""}},
    rogue = {{""}},

    -- v1.0.1
    adam = {{""}},
    meredith = {{""}},
    jackie = {{""}},
    kerry = {{""}},
    tbug = {{""}},
    dexter = {{""}},
    viktor = {{""}}
}

registerForEvent('onInit', function()
    GameSession.StoreInDir('sessions') -- Set directory to store session data
    GameSession.Persist(chatState) -- Link the data that should be watched and persisted 

    -- Whenever we load into the game, get the chat history accordingly and send out a custom primer for this history.
    GameSession.OnLoad(function()
        -- For each chat id, create a flat in the games' internal database
        -- Cyberchat gets these values and lists available chats accordingly
        -- The idea here is that anyone can write extensions of cyberchat simply by adding custom handles:
        -- 1) Add custom handle to list of ALL_PROFILES (semicolon-separated) & in the chatState table above
        --      IT NEEDS TO BE LOWER CAPS IN THE TABLE & STARTING UPPERCASE IN THE PROFILE LIST
        -- 2) Define metadata, such as handle, name, optional logo and primer
        --      THE FLATS WILL BE MATCHED TO THE PROFILE BY THEIR TEMPLATE NAME (e.g., "CyberChat.<Profile>_handle")
        -- 3) (Optional) define a condition (fact name) under which the chat is displayed
        TweakDB:SetFlat("CyberChat.ALL_PROFILES", "Panam;Judy;Johnny;Rogue;Adam;Viktor")

        -- v1.0.0 profiles: (Panam;Judy;Johnny;Rogue)
        -- v1.0.1 profiles (WIP): (Adam;Meredith;Jackie;Kerry;TBug;Dexter;Viktor)

        local profileDB = require("profileDB")

        for k,v in pairs(profileDB) do
            TweakDB:SetFlat("CyberChat." .. v[1] .. "_handle", v[2])
            TweakDB:SetFlat("CyberChat." .. v[1] .. "_name", v[3])
            TweakDB:SetFlat("CyberChat." .. v[1] .. "_logoPath", v[4])
            TweakDB:SetFlat("CyberChat." .. v[1] .. "_logo", v[5])
            TweakDB:SetFlat("CyberChat." .. v[1] .. "_condition", v[6])
            TweakDB:SetFlat("CyberChat." .. v[1] .. "_primer1", v[7])
            TweakDB:SetFlat("CyberChat." .. v[1] .. "_primer2", v[8])
        end

        -- Here we handle this logic on our own, by sending out a primer. Notice that this is only slightly less efficient than before.
        -- i.e., any persistent chat history needs to be sent to OpenAI on session anyways! This only adds one message per chat overhead
        -- which means only if you have a ton of open chats this will make a difference. However, the number of story characters is severly limited.
        for k,v in pairs(chatState) do
            -- Since we send out a primer on our own, we have to flush the chat inbetween sessions (else CyberAI would keep it).
            -- this also makes sense since chats between sessions could not incorporate session facts..
            --print('[CyberChat-ext] Flushing remains of existing chats..')
            FlushChat("@" .. k)

            if #v < 2 then
                -- If there is no chatHistory for this key in this session
                print('[CyberChat-ext] There is no chat history for ' .. k .. ', wait for user initiation..')
            else
                -- If instead we have a chatHistory for this key in this session
                print('[CyberChat-ext] Dispatching chat history primer for ' .. k)
                table.insert(chatState[k], {"System","(The user is back online, act suprised, relieved or sarcastic)"})
                ScheduleChatCompletionRequest("@" .. k, v)
            end
        end

        --[[
        if #chatState.chatHistory < 2 then
            -- If there is no chatHistory for this session (or id..)
            print('[CyberChat-ext] There is no chat history, wait for user initiation..')
         else
              -- If we have a chatHistory for this session (and id...)
              print('[CyberChat-ext] Dispatching chat history primer..')
              table.insert(chatState.chatHistory, {"System","(The user is back online, act suprised, glad or sarcastic)"})
              ScheduleChatCompletionRequest("@panam", chatState.chatHistory)
        end
        ]]--
    end)

    -- This saves the full chat interaction locally every 5 seconds.
    Cron.Every(5.0, { tick = 1 }, function(timer)
        -- At this time, we need to manually list possible handles to be persisted.
        -- This could be made so arbitrary handles are supported in the future. But would that make sense? For open-world NPCs maybe
        -- However, there are really not that many story-relevant NPCs in Cyberpunk2077
        for k,v in pairs(chatState) do
            chatState[k] = GetHistory("@" .. k)
        end
        -- print(('[CyberChat-ext] [%s] Every %.2f secs: Chat(s) saved.'):format(os.date('%H:%M:%S'), timer.interval))
    end)
end)

registerForEvent('onUpdate', function(delta)
    -- This is required for Cron to function
    Cron.Update(delta)
end)