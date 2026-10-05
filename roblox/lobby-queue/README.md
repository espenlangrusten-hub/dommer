# Lobby queue pads (Roblox)

Queue pads like in the reference video:

1. Walk onto an empty pad → you're placed on it and the **Create Party** menu opens.
2. Pick a party size (1–5) and press **Create** → the countdown starts above the pad (`1/4`, `0:20`).
3. Other players who touch the pad get placed on it until it's full.
4. **When the pad is full the timer goes 5x faster.**
5. When the timer hits 0 the party is sent to the game.
6. The red **exit** button takes you off the pad. **X** on the menu cancels it.

## Install

| File | Put it in | Type |
|---|---|---|
| `LobbyQueueServer.server.lua` | ServerScriptService | Script |
| `LobbyQueueClient.client.lua` | StarterPlayer › StarterPlayerScripts | LocalScript |

Make a Folder named **`LobbyPads`** in Workspace and put a flat Part in it for each pad.
The script adds the yellow outline and the counter/timer sign. If there's no `LobbyPads`
folder, a demo pad is spawned at (0, 0, 25) so you can press Play right away.

## Settings (top of the server script)

| Setting | Default | What it does |
|---|---|---|
| `MAX_PARTY_SIZE` | 5 | Biggest size on the menu |
| `COUNTDOWN` | 20 | Seconds before the match starts |
| `FULL_SPEED_MULTIPLIER` | 5 | Timer speed while the pad is full |
| `CHOOSE_TIMEOUT` | 30 | Host gets kicked off if they never press Create |
| `REJOIN_COOLDOWN` | 2 | Seconds before you can touch a pad again after leaving |
| `GAME_PLACE_ID` | 0 | Your game's PlaceId. When set, parties are teleported to a reserved server |

When `GAME_PLACE_ID` is 0, players are moved to a Part named `MatchSpawn` (if there is one),
and `ReplicatedStorage.LobbyQueueRemotes.MatchStarted` (a BindableEvent) fires with
`(players, pad)` so your own server code can start the round.

Teleporting doesn't work in Studio. Test it in a published game.
