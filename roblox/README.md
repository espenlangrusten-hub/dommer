# 3D Card Roll System (Roblox / Luau)

A gacha-style card roll built to match the reference clip: press **ROLL** at the
bottom of the screen, three cards fly in face-down, flip up one by one with a
rarity-coloured border and glow, lean toward your cursor in 3D, and you click one
to keep it.

## What is in the box

| File | Runs on | Job |
| --- | --- | --- |
| `ReplicatedStorage/CardSystem/Config.luau` | both | every tunable number |
| `ReplicatedStorage/CardSystem/Rarities.luau` | both | tiers, weights, colours |
| `ReplicatedStorage/CardSystem/Cards.luau` | both | the card catalogue |
| `ReplicatedStorage/CardSystem/RollLogic.luau` | both | weighted pick + pity |
| `ReplicatedStorage/CardSystem/Remotes.luau` | both | names the network surface |
| `ServerScriptService/CardSystem/init.server.luau` | server | authority, cooldown, awards |
| `ServerScriptService/CardSystem/Inventory.luau` | server | counts, leaderstats, saving |
| `StarterPlayerScripts/CardClient/init.client.luau` | client | state machine, input, render loop |
| `StarterPlayerScripts/CardClient/CardVisual.luau` | client | one 3D card |
| `StarterPlayerScripts/CardClient/RollUI.luau` | client | roll button, odds, banner |

## Install with Rojo

```bash
rojo serve roblox/default.project.json
```

Then connect from the Rojo plugin in Studio. The project maps into
`ReplicatedStorage`, `ServerScriptService` and `StarterPlayer.StarterPlayerScripts`.

## Install by hand (no Rojo)

1. `ReplicatedStorage` → new **Folder** named `CardSystem`. Inside it create five
   **ModuleScript**s named `Config`, `Rarities`, `Cards`, `RollLogic`, `Remotes`
   and paste the matching file into each.
2. `ServerScriptService` → new **Script** named `CardSystem`, paste
   `init.server.luau` into it. Add a **ModuleScript** child named `Inventory`.
3. `StarterPlayer` → `StarterPlayerScripts` → new **LocalScript** named
   `CardClient`, paste `init.client.luau` into it. Add two **ModuleScript**
   children named `CardVisual` and `RollUI`.

Names matter: every `require` looks the modules up by name.

## How a roll flows

1. Client presses ROLL and fires `RequestRoll`. Nothing is decided locally.
2. Server checks the cooldown and that no hand is already pending, rolls
   `Config.CardsPerRoll` cards with its own `Random`, stores them against a roll
   id, and fires `RollResult`.
3. Client freezes a spawn point in front of the camera, builds one anchored Part
   per card, and animates entrance, flip, cursor tilt and hover from a single
   `RenderStepped` pass.
4. Click a card and the client sends `SelectCard(rollId, slot)`. The server
   validates the id and the slot, awards the card, updates leaderstats and
   replies. A slot the server did not deal is rejected.

The client only ever renders what the server sent, so editing the local scripts
cannot change what drops.

## Tuning

Everything lives in `Config.luau`:

- `CardsPerRoll`, `RollCooldown` - roll rules.
- `PityRolls`, `PityMinimumRarity` - after this many rolls with nothing good, one
  card in the hand is upgraded. Set `PityRolls = 0` to switch it off.
- `CardSize`, `CardSpacing`, `CameraDistance` - how the hand is laid out.
- `MaxTilt`, `TiltSmoothing`, `HoverPop`, `HoverScale` - the 3D lean.
- `EnterDuration`, `FlipDuration`, `FlipStagger` - reveal pacing.
- `Sounds` - drop in `rbxassetid://` strings; empty strings stay silent.

## Adding cards

Append to the list in `Cards.luau`:

```lua
{ Id = "sunspear", Name = "Sunspear", Rarity = "Legendary", Icon = "rbxassetid://123456789", Flavor = "It only sets when you do." },
```

`Id` must be unique and `Rarity` must match a tier in `Rarities.luau`. Leave
`Icon = ""` and the card draws the name's first letter instead, so a card works
before its art exists. Every tier needs at least one card; the module asserts on
load if one is empty.

## Adding or rebalancing rarities

`Weight` is relative, not a percentage. The odds strip under the roll button
recomputes itself from the weights, so adding a tier needs no other edit.

| Tier | Weight | Chance per card |
| --- | --- | --- |
| Common | 1000 | 53.88% |
| Uncommon | 520 | 28.02% |
| Rare | 220 | 11.85% |
| Epic | 90 | 4.85% |
| Legendary | 22 | 1.19% |
| Mythic | 4 | 0.22% |

Weights total 1856. With three cards per roll, 17.6% of hands
contain at least one Epic or better.

## Saving

`Inventory.luau` writes to the `CardInventory_v1` DataStore. Every call is
wrapped in `pcall`; if DataStores are unavailable (an unpublished place, or
Studio without API access enabled) it warns once and keeps inventories in memory
for the session. Set `SAVE_ENABLED = false` at the top of the module to skip
DataStores entirely.

## Verifying it outside Studio

The data modules are pure Luau, so the roll math can be checked without opening
Roblox:

```bash
python3 roblox/tests/run.py path/to/luau
```

It rolls 300,000 hands and asserts the observed rarity frequencies match the
configured weights, that the pity counter caps dry streaks, and that every card
in the catalogue is reachable. Re-run it after changing any weight.

The whole tree also type-checks against the real Roblox API with
[luau-lsp](https://github.com/JohnnyMorganz/luau-lsp):

```bash
luau-lsp analyze --definitions=globalTypes.d.luau --no-strict-dm-types \
  $(find roblox/src -name "*.luau")
```

## Known limits

- Cards spawn in world space in front of the camera. In a cramped room they can
  clip through walls. Raise `Config.CameraDistance` or spawn the hand in a
  dedicated ViewportFrame if that matters for your game.
- A pending hand blocks the next roll until a card is picked. There is no
  auto-pick timeout.
- The catalogue ships without art. Point `Icon` at your own decals.
