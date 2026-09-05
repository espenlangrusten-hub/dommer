# Getting this into Roblox Studio

Three files, three drops, no tooling. Takes about a minute.

## 1. Get the files

They are in `roblox/build/`:

| File | Goes into |
| --- | --- |
| `CardSystem_ReplicatedStorage.rbxmx` | `ReplicatedStorage` |
| `CardSystem_ServerScriptService.rbxmx` | `ServerScriptService` |
| `CardClient_StarterPlayerScripts.rbxmx` | `StarterPlayer` > `StarterPlayerScripts` |

Download all three to your computer.

## 2. Drop them in

1. Open your place in Roblox Studio.
2. If you cannot see the Explorer panel: **View** tab → **Explorer**.
3. In Explorer, right-click **ReplicatedStorage** → **Insert from File...** →
   pick `CardSystem_ReplicatedStorage.rbxmx`.
4. Right-click **ServerScriptService** → **Insert from File...** →
   pick `CardSystem_ServerScriptService.rbxmx`.
5. Expand **StarterPlayer**, right-click **StarterPlayerScripts** →
   **Insert from File...** → pick `CardClient_StarterPlayerScripts.rbxmx`.

Newer Studio versions renamed that menu entry. If you do not see
**Insert from File...**, use **Insert** → **Import Roblox Model**, which opens
the same file picker. If the imported folder lands in Workspace instead of the
service you right-clicked, just drag it onto the right service in the Explorer.

**Replacing an older copy?** Delete the previous `CardSystem` / `CardClient`
objects first, then import. Two copies would both run and fight over the UI.

Insert each file into the service itself, not next to it. When you are done the
Explorer should look like this:

```
ReplicatedStorage
└── CardSystem            (Folder)
    ├── Cards             (ModuleScript)
    ├── Categories        (ModuleScript)
    ├── Config            (ModuleScript)
    ├── Rarities          (ModuleScript)
    ├── Remotes           (ModuleScript)
    ├── RollLogic         (ModuleScript)
    └── Theme             (ModuleScript)

ServerScriptService
└── CardSystem            (Script)
    └── Inventory         (ModuleScript)

StarterPlayer
└── StarterPlayerScripts
    └── CardClient        (LocalScript)
        ├── CardVisual    (ModuleScript)
        ├── Hotbar        (ModuleScript)
        ├── InventoryUI   (ModuleScript)
        ├── Profile       (ModuleScript)
        ├── RollUI        (ModuleScript)
        └── Showcase      (ModuleScript)
```

## 3. Play it

Press **F5** (or the Play button).

| Input | Does |
| --- | --- |
| `ROLL` button or `R` | roll three cards |
| Click a card | keep it |
| `Items` button on the left, or `E` | open and close the inventory |
| Hover a slot | tooltip with rarity, description and View / Equip |
| `View` | full-screen item showcase, click anywhere to dismiss |
| `1` - `6` | select a hotbar slot |

The hotbar runs along the bottom, all six slots open. Your card count shows in
the player list, top right.

You cannot walk while a hand of cards or the showcase is on screen. That is
deliberate, so you cannot leave them floating behind you.

The stock Roblox backpack is hidden on join, because it sits exactly where the
hotbar goes. Set `HideDefaultBackpack = false` in `Config` to keep it.

## If something looks wrong

**No roll button.** The `CardClient` LocalScript has to be inside
`StarterPlayerScripts`, not directly under `StarterPlayer`. Drag it in if it
landed one level too high.

**Red text in the Output window.** Open **View** → **Output** and read the first
error. It almost always names a module that ended up in the wrong place or under
the wrong name. Names matter: every `require` looks the modules up by name.

**A DataStore warning on start.** Normal in Studio. Card inventories then live
in memory for that session only. To save them for real, publish the place and
turn on **Game Settings** → **Security** → **Enable Studio Access to API
Services**. Nothing else breaks either way.

**Cards clip through a wall.** They spawn 9 studs in front of the camera. Open
`ReplicatedStorage.CardSystem.Config` and raise `CameraDistance`, or lower it in
a tight room.

**The inventory is empty.** It only lists cards you own, so roll and keep a few
first.

**Two hotbars, or the UI drawn twice.** An older copy of the scripts is still
in the place. Delete the duplicate `CardClient` under StarterPlayerScripts.

## Sounds

The system ships silent. To add the card reveal tick or any other sound, upload
the audio in Studio (**View** → **Asset Manager** → **Audio** → **+**), wait for
moderation, right-click it → **Copy Asset ID**, and paste the id into
`ReplicatedStorage.CardSystem.Config` under `Sounds.Reveal`:

```lua
Reveal = "rbxassetid://123456789",
```

`Reveal` plays once per card as it flips face up. The other entries are listed
in `roblox/README.md`.

## Changing things

Everything tunable is in `ReplicatedStorage.CardSystem.Config` - roll cooldown,
card size and spacing, animation speed, cursor lean, the screen layout and the
keybinds. Cards live in `Cards`, rarity tiers and their odds in `Rarities`, the
inventory tabs in `Categories`, and every colour and font in `Theme`. See
`roblox/README.md` for the details.

## Rebuilding these files

If you edit the sources in this repo and want fresh drop-in files:

```bash
python3 roblox/tools/build_rbxmx.py
```

Editing the scripts directly inside Studio works too. The `.rbxmx` files are
just a delivery format, not a live link.
