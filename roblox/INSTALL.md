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

Insert each file into the service itself, not next to it. When you are done the
Explorer should look like this:

```
ReplicatedStorage
└── CardSystem            (Folder)
    ├── Config            (ModuleScript)
    ├── Rarities          (ModuleScript)
    ├── Cards             (ModuleScript)
    ├── RollLogic         (ModuleScript)
    └── Remotes           (ModuleScript)

ServerScriptService
└── CardSystem            (Script)
    └── Inventory         (ModuleScript)

StarterPlayer
└── StarterPlayerScripts
    └── CardClient        (LocalScript)
        ├── CardVisual    (ModuleScript)
        └── RollUI        (ModuleScript)
```

## 3. Play it

Press **F5** (or the Play button). A blue **ROLL** button sits at the bottom of
the screen. Press it, three cards fly in and flip up, then click one to keep it.
The `R` key rolls too.

Your card count shows in the player list, top right.

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

## Changing things

Everything tunable is in `ReplicatedStorage.CardSystem.Config` - roll cooldown,
card size and spacing, animation speed, how far cards lean toward the cursor.
Cards live in `Cards`, rarity tiers and their odds in `Rarities`. See
`roblox/README.md` for the details.

## Rebuilding these files

If you edit the sources in this repo and want fresh drop-in files:

```bash
python3 roblox/tools/build_rbxmx.py
```

Editing the scripts directly inside Studio works too. The `.rbxmx` files are
just a delivery format, not a live link.
