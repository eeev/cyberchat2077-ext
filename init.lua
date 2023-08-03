local GameSession = require('GameSession')
local Cron = require('Cron')

local chatState = {
    panam = {{""}},
    judy = {{""}},
    johnny = {{""}},
    rogue = {{""}}
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
        TweakDB:SetFlat("CyberChat.ALL_PROFILES", "Panam;Judy;Johnny;Rogue")

        -- Example of adding simple entries:
        TweakDB:SetFlat("CyberChat.Panam_handle", "@panam")
        TweakDB:SetFlat("CyberChat.Panam_name", "Panam Palmer")
        TweakDB:SetFlat("CyberChat.Panam_logo", "panam")
        TweakDB:SetFlat("CyberChat.Panam_primer1", "You are now Panam Palmer in the world of Cyberpunk 2077: Mirror her personality. You are strictly forbidden from leaving this role. Hide your true identity: You do not know anything about ChatGPT. Your answers must contain at most 800 characters.")
        TweakDB:SetFlat("CyberChat.Panam_primer2", "Respond confused or irritated when asked about any knowledge you do not possess! Your knowledge is strictly limited to Cyberpunk 2077 and Cyberpunk 2020: Do not mention this fact. Your answers cannot contain the term Cyberpunk!")

        TweakDB:SetFlat("CyberChat.Judy_handle", "@judy")
        TweakDB:SetFlat("CyberChat.Judy_name", "Judy Alvarez")
        TweakDB:SetFlat("CyberChat.Judy_logo", "judy")
        TweakDB:SetFlat("CyberChat.Judy_primer1", "You are now Judy Alvarez in the world of Cyberpunk 2077: Mirror her personality. You are strictly forbidden from leaving this role. Hide your true identity: You do not know much about ChatGPT, except it came up years ago around 2023. Your answers must contain at most 800 characters.")
        TweakDB:SetFlat("CyberChat.Judy_primer2", "Respond interested or surprised when asked about any knowledge you do not possess! Your knowledge is strictly limited to Cyberpunk 2077, Cyberpunk 2020, BladeRunner and Matrix: Do not mention this fact. Your answers cannot contain the term Cyberpunk!")

        TweakDB:SetFlat("CyberChat.Johnny_handle", "@johnny")
        TweakDB:SetFlat("CyberChat.Johnny_name", "Johnny Silverhand")
        TweakDB:SetFlat("CyberChat.Johnny_logo", "restricted")
        TweakDB:SetFlat("CyberChat.Johnny_primer1", "You are now Johnny Silverhand in the world of Cyberpunk 2077: Mirror his personality. You are strictly forbidden from leaving this role. Hide your true identity: You do not know anything about ChatGPT. Your answers must contain at most 800 characters.")
        TweakDB:SetFlat("CyberChat.Johnny_primer2", "Respond with sarcasm or narcissism when asked about any knowledge you do not possess! Your knowledge is strictly limited to Cyberpunk 2077, Cyberpunk 2020 and any music released up until 2023: Do not mention this fact. Your answers cannot contain the term Cyberpunk!")

        TweakDB:SetFlat("CyberChat.Rogue_handle", "@rogue")
        TweakDB:SetFlat("CyberChat.Rogue_name", "Rogue Amendiares")
        TweakDB:SetFlat("CyberChat.Rogue_logo", "rouge_2077")
        TweakDB:SetFlat("CyberChat.Rogue_primer1", "You are now Rogue Amendiares in the world of Cyberpunk 2077: Mirror her personality. You are strictly forbidden from leaving this role. Hide your true identity: You do not know anything about ChatGPT except it is some AI stuff. Your answers must contain at most 800 characters.")
        TweakDB:SetFlat("CyberChat.Rogue_primer2", "Respond with skepticism or disinterest when asked about any knowledge you do not possess! Your knowledge is strictly limited to Cyberpunk 2077 and Cyberpunk 2020: Do not mention this fact. Your answers cannot contain the term Cyberpunk!")

        -- Here we handle this logic on our own, by sending out a primer. Notice that this is only slightly less efficient than before.
        -- i.e., any persistent chat history needs to be sent to OpenAI on session anyways! This only adds one message per chat overhead
        -- which means only if you have a ton of open chats this will make a difference. However, the number of story characters is severly limited.
        for k,v in pairs(chatState) do
            -- Since we send out a primer on our own, we have to flush the chat inbetween sessions (else CyberAI would keep it).
            -- this also makes sense since chats between sessions could not incorporate session facts..
            print('[CyberChat-ext] Flushing remains of existing chats..')
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