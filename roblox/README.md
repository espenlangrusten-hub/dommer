# 3D Card System (Roblox / Luau)

A gacha card roll, an inventory panel, a hotbar and a full-screen item
showcase, built to match the two reference clips.

- Press **ROLL**: three cards fly in face-down, flip up one by one with a
  rarity-coloured border and glow, lean toward your cursor in 3D, and you click
  one to keep it.
- Press **E**: the inventory opens - green banner header, red close button,
  coloured tab strip, search field, and a scrolling grid of tinted slots with a
  gold count in the corner. Hovering a slot raises a tooltip with the name,
  rarity, description, owned count, and View / Equip buttons.
- **View** opens the showcase: the item floats in front of the camera under a
  burst of sparks with its details beside it, and any click dismisses it.
- The **hotbar** runs along the bottom: six slots you can equip cards into,
  selected with the number keys.

While a hand of cards or the showcase is on screen the character is frozen, so
you cannot walk off and leave them floating behind you.

## Install

Easiest path: **[INSTALL.md](INSTALL.md)** - three ready-made `.rbxmx` files in
`build/` that you insert straight into Studio, no tooling required.

The two developer paths follow.

## Install with Rojo

```bash
rojo serve roblox/default.project.json
```

Then connect from the Rojo plugin in Studio. The project maps into
`ReplicatedStorage`, `ServerScriptService` and `StarterPlayer.StarterPlayerScripts`.

## What is in the box

| File | Runs on | Job |
| --- | --- | --- |
| `ReplicatedStorage/CardSystem/Config.luau` | both | every tunable number |
| `ReplicatedStorage/CardSystem/Theme.luau` | both | palette, font and UI builders |
| `ReplicatedStorage/CardSystem/Rarities.luau` | both | tiers, weights, colours |
| `ReplicatedStorage/CardSystem/Categories.luau` | both | the inventory tabs |
| `ReplicatedStorage/CardSystem/Cards.luau` | both | the card catalogue |
| `ReplicatedStorage/CardSystem/RollLogic.luau` | both | weighted pick + pity |
| `ReplicatedStorage/CardSystem/Remotes.luau` | both | names the network surface |
| `ServerScriptService/CardSystem/init.server.luau` | server | authority, cooldown, awards |
| `ServerScriptService/CardSystem/Inventory.luau` | server | profile, hotbar, saving |
| `StarterPlayerScripts/CardClient/init.client.luau` | client | wiring, input, render loop |
| `StarterPlayerScripts/CardClient/Profile.luau` | client | the client's copy of the profile |
| `StarterPlayerScripts/CardClient/CardVisual.luau` | client | one 3D card |
| `StarterPlayerScripts/CardClient/RollUI.luau` | client | roll button, odds, notices |
| `StarterPlayerScripts/CardClient/InventoryUI.luau` | client | the inventory panel |
| `StarterPlayerScripts/CardClient/Hotbar.luau` | client | the hotbar |
| `StarterPlayerScripts/CardClient/Showcase.luau` | client | the item showcase |

## How it hangs together

The server is the only thing that decides anything:

1. Client presses ROLL and fires `RequestRoll`. Nothing is decided locally.
2. Server checks the cooldown and that no hand is already pending, rolls three
   cards with its own `Random`, stores them against a roll id, and fires
   `RollResult`.
3. Client freezes a spawn point in front of the camera, builds one anchored
   Part per card, and animates entrance, flip, cursor tilt and hover from a
   single `RenderStepped` pass.
4. Click a card and the client sends `SelectCard(rollId, slot)`. The server
   validates the id and the slot, grants the card, then pushes a
   `ProfileSync` with the whole profile.
5. Every panel reads from `Profile`, the client's copy of that snapshot, so the
   hotbar, the inventory and the showcase can never disagree.

Equipping works the same way: the client asks, the server checks that the card
is owned and the slot exists, and either syncs the new profile or sends back a
`Notice` explaining the refusal.

## Controls

| Input | Does |
| --- | --- |
| `ROLL` button or `R` | roll three cards |
| Click a card | keep it |
| `Items` button or `E` | open and close the inventory |
| `Esc` | close the inventory |
| `1` - `6` | select a hotbar slot |
| Click anywhere | dismiss the showcase |

There is no level or XP system. If you want gated hotbar slots back, add the
condition to `Inventory.equip` on the server and draw the locked state in
`Hotbar.refresh`.

The stock Roblox backpack sits exactly where the hotbar goes, so it is hidden
on join. Set `Config.HideDefaultBackpack = false` to keep it.

Movement is locked while cards or the showcase are up. Set
`Config.LockMovementDuringCards = false` to allow walking during a reveal.

## Tuning

Everything lives in `Config.luau`:

- `CardsPerRoll`, `RollCooldown` - roll rules.
- `PityRolls`, `PityMinimumRarity` - after this many rolls with nothing good,
  one card in the hand is upgraded. Set `PityRolls = 0` to switch it off.
- `CardSize`, `CardSpacing`, `CameraDistance` - how the hand is laid out.
- `MaxTilt`, `TiltSmoothing`, `HoverPop`, `HoverScale` - the 3D lean.
- `Layout` - where the hotbar and roll button sit.
- `Hotbar.Slots` - how many hotbar slots there are.
- `Inventory.Columns`, `SlotSize` - the grid.
- `Keys` - the keybinds.
- `LockMovementDuringCards` - freeze the character during a reveal.
- `Sounds` - drop in `rbxassetid://` strings; empty strings stay silent. See
  **Adding sounds** below.

Colours and the font are in `Theme.luau`. The reference UI uses a halftone dot
texture behind every slot: upload one, paste its id into `Theme.DotTexture`,
and every panel picks it up. While it is empty the slots use a two-stop
gradient, which reads almost the same at slot size.

## Adding artwork

Like audio, images have to live on Roblox's servers before the game can use
them. Upload in Studio via **View** → **Asset Manager** → **Images** → **+**,
then right-click an asset → **Copy Asset ID**.

All the ids go in `Theme.Images`. Every one is optional: an empty string keeps
the drawn fallback, so the UI works with no art at all and improves one id at a
time.

```lua
Theme.Images = {
    RollButton = "rbxassetid://123456789",
    HotbarSlots = { "rbxassetid://...", "rbxassetid://...", "", "", "", "" },
}
```

**Roll button.** The artwork is expected to carry the word ROLL, so the
button's own text is hidden when an id is set. The cooldown then counts down on
a small strip below the button rather than covering the art. The button box is
`Layout.RollWidth` x `Layout.RollHeight`, 240 x 106 by default; match your art's
aspect ratio there or it will stretch.

**Hotbar slots.** One frame per slot, in order. Art is assumed to carry its own
border and slot number, so the drawn frame and the number badge are both
skipped for that slot.

Art with a tab or ear sticking out of the top - a slot number, a ribbon - is
taller than its square body. `Theme.SlotArt.BodyHeightRatio` says how much of
the image's height that body takes up, so the body can line up with the slot
while the tab overhangs instead of being squashed into it. `WidthRatio` does
the same sideways. Measure your file: a 344 x 385 image whose body is the
bottom 330px gives `BodyHeightRatio = 330 / 385 = 0.857`.

**Rarity colours from one image.** Set `Theme.SlotArt.Tint = true` and slot art
is tinted by the rarity of whatever sits in it. Tinting multiplies, so it only
works on art whose body is white or near white: black outlines stay black and
the body takes the colour, giving all six tiers from a single file. Art that is
already coloured goes muddy, so leave it false for that.

## Adding sounds

Roblox will only play audio that lives on its own servers, so a local file has
to be uploaded first. There is no way around this.

1. In Studio open **View** → **Asset Manager**.
2. Click **Audio**, then the **+** (or **Bulk Import**), and pick your file.
   Roblox accepts `.mp3` and `.ogg` up to seven minutes.
3. Wait for moderation. It usually takes under a minute for a short clip, and
   the asset shows up greyed out until it passes.
4. Right-click the uploaded sound → **Copy Asset ID**.
5. Open `ReplicatedStorage.CardSystem.Config` and paste it in:

```lua
Sounds = {
    Roll = "",
    Reveal = "rbxassetid://123456789",
    ...
},
```

| Entry | Fires when |
| --- | --- |
| `Roll` | the hand is dealt |
| `Reveal` | each card turns face up, once per card |
| `Select` | you keep a card |
| `Rare` | you keep an Epic or better, instead of `Select` |
| `Open` / `Close` | the inventory opens and closes |

`RevealPitchStep` raises the playback speed a little for each later card in the
hand, so three reveals in a row rise in pitch instead of sounding identical.
Set it to `0` for three identical ticks. `SoundVolume` sets the level for all
of them.

## Adding cards

Append to the list in `Cards.luau`:

```lua
{ Id = "sunspear", Name = "Sunspear", Rarity = "Legendary", Category = "Weapons",
  Icon = "rbxassetid://123456789", Flavor = "It only sets when you do.",
  Description = "Deals bonus damage at noon." },
```

`Id` must be unique, `Rarity` must match a tier in `Rarities.luau`, and
`Category` must match one in `Categories.luau`. Leave `Icon = ""` and the card
draws the name's first letter instead, so a card works before its art exists.
The module asserts on load if a rarity or a category ends up with no cards.

Adding a category to `Categories.luau` makes a new tab appear with no other
edits.

## Rarity odds

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

Weights total 1856. With three cards per roll, 17.6% of hands contain at least
one Epic or better.

## Saving

`Inventory.luau` writes to the `CardInventory_v2` DataStore: owned counts, the
pity counter and the equipped hotbar. Every call is wrapped in `pcall`; if
DataStores are unavailable (an unpublished place, or Studio without API access
enabled) it warns once and keeps profiles in memory for the session. Set
`SAVE_ENABLED = false` at the top of the module to skip DataStores entirely.

Loaded saves are sanitised: cards that no longer exist in the catalogue are
dropped, and an equipped slot pointing at a card the player does not own is
cleared.

## Verifying it outside Studio

The data modules are pure Luau, so the maths can be checked without opening
Roblox:

```bash
python3 roblox/tests/run.py path/to/luau
```

It rolls 300,000 hands and asserts the observed rarity frequencies match the
configured weights, that the pity counter caps dry streaks, that every card is
reachable, and that no tab would render empty. Re-run it after changing any
weight.

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
- Equipping a card is tracked and saved, but it has no gameplay effect yet.
  `Hotbar.OnSlotActivated` in the client is where you hook one up.

## Sending the code to someone

To hand the scripts to someone who does not have this repo:

```bash
python3 roblox/tools/export_plain.py
```

It writes `roblox/build/card-system-source.txt`: every script in one file,
comments stripped, each one headed by the exact name and location it needs in
Studio. Paste it into a GitHub Gist, or send the file directly.

Stripping is done with a character scanner rather than a regular expression,
because `--` only opens a comment outside of a string - short strings, Luau
backtick strings and long bracket strings all have to be skipped intact. The
result is verified by compiling both versions and comparing instruction-level
bytecode, which matches for every file.

The sources under `roblox/src` keep their comments.
