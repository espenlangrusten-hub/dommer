# Roblox Egg System

`EggSystem.server.lua` is a single server **Script**. Put it in `ServerScriptService`.

## What it needs in your place
| Thing | Name | Notes |
|---|---|---|
| Egg models | `Basic egg`, `Blue egg`, `Gold egg`, `Green egg`, `Orange egg`, `Purple egg`, `Red egg` | Found anywhere in Workspace / ServerStorage / ReplicatedStorage. If they're in Workspace they get moved to ServerStorage when the game starts. |
| Pets folder | `Pet's` | Every Model inside it is a possible pet (`chicken`, `goldenpeacock`, …). |
| Spawn area | `spawn area` | Folder with the platform part(s). Eggs spawn on top of them. |
| Bases | `Bases` folder in Workspace | One Part (or a Model with a part named `Floor`) per player. If it's missing, 6 simple grass bases are created automatically. |

## Rarities (edit the `EGGS` table)
| Egg | Rarity | Tag colour | Hatch time | Spawn weight |
|---|---|---|---|---|
| Basic egg | Common | grey | 10 s | 40 |
| Green egg | Uncommon | white | 20 s | 25 |
| Blue egg | Rare | blue | 30 s | 15 |
| Purple egg | Epic | purple | 45 s | 10 |
| Orange egg | Legendary | orange | 60 s | 5 |
| Red egg | Mythic | red | 90 s | 3 |
| Gold egg | Godly | gold | 120 s | 2 |
