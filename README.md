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

- Move this folder into `%CyberpunkDir%\bin\x64\plugins\cyber_engine_tweaks\mods`