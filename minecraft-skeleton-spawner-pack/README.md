# Skeleton Spawner Pack

A Minecraft (Java Edition) resource pack that makes **Gold Blocks** look like a
spawner and renames them to **Skeleton Spawner**.

## Install
1. Download `SkeletonSpawnerPack.zip` from this folder.
2. Put it in your `.minecraft/resourcepacks` folder
   (in game: Options → Resource Packs → Open Pack Folder).
3. Enable it in Options → Resource Packs.

## What it changes
- `models/block/gold_block.json` – uses the vanilla spawner texture (the item in
  your inventory uses this model too).
- `lang/*.json` – renames "Block of Gold" to "Skeleton Spawner"
  (English, Norwegian).

## Limits
- It is a texture swap only. The block still behaves like a gold block (no mobs spawn).
- No spinning skeleton inside: that part of a real spawner is drawn by game code,
  which a resource pack can't add.
- Gold blocks render as solid blocks, so the see-through gaps in the spawner
  cage show as dark instead of transparent.
- Made for Java Edition 1.21.9 – 1.21.11. Not for Bedrock.
