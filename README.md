# cyberchat2077-ext

This is a requirement for [cyberchat2077](https://github.com/eeev/cyberchat2077) to work properly. It adds:

- [x] Persistent chats
    - Stored on a game session basis (i.e., the game has to be saved)
    - Will save chats every 10 seconds by default
    - Stored in `./sessions/<session_id>.lua`
    - Sends custom primer on game loading
        - Chat partner will try to continue the conversation
- [x] Multiple chats backend
    - Mirrors CyberAI's k/v store for chat conversations
    - Each chat is persisted individually
- [x] Enable custom chat creation
    - Define your own conversation partners & associated primers
- [ ] In-game conversation fact tracker
    - Limit or extend chat partner knowledge based on game progress
- [ ] Message notification agent
    - Display UI notification on new message

## Installation

1) Download and install the necessary requirements:
    - [Cyber Engine Tweaks (CET)](https://www.nexusmods.com/cyberpunk2077/mods/107) v1.25.2 ([GitHub](https://github.com/maximegmd/CyberEngineTweaks))
2) Move this folder into `%CyberpunkDir%\bin\x64\plugins\cyber_engine_tweaks\mods`

## Configuration

You may configure this extension by writing your own code inside `init.lua`. Currently, all existing chat character profiles are listed there, you can add your own ones by following the pattern denoted in the code comments:
1) Add your new chat partner's first name to the `CyberChat.ALL_PROFILES` flat (this is a semicolon-separated list)
2) Copy the existing pattern of creating the other 5 flats: `handle`, `name`, `logo`, `primer1` and `primer2`
    - All of the inputs are `Strings`
    - The `logo` is the texture part from the atlas resource that your [cyberchat2077 configuration](https://github.com/eeev/cyberchat2077#configuration) points to
    - `primer1` and `primer2` essentially tell the language model who they are role-playing as ([examples here](https://github.com/eeev/cyberchat2077#configuration))