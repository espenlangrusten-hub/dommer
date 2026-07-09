# Auto Captions (After Effects CEP panel)

Transcribes the audio of a selected layer and generates text layers whose
words type themselves out on the timeline exactly when they're spoken —
one word (or short phrase) per layer, character-revealed in sync with the
speech.

Speech-to-text is done via OpenAI's Whisper API (word-level timestamps).
You need your own OpenAI API key; usage is billed to your OpenAI account
per their audio transcription pricing.

## How it works

- **`client/`** — the panel UI (plain HTML/CSS/JS). Runs with Node.js
  enabled (CEP "mixed context"), so it can read the source file from disk
  and call the OpenAI API directly over HTTPS — no bundler/build step.
- **`host/index.jsx`** — ExtendScript that runs inside After Effects. It
  creates one box-text layer per caption group and keyframes `Source Text`
  so each word's letters appear progressively across that word's own
  start/end time.
- **`CSXS/manifest.xml`** — the CEP extension manifest.

## Install (development / unsigned extension)

1. **Enable unsigned extensions** (one-time, per machine). CEP version
   depends on your After Effects release, so set it for a couple of
   likely versions to be safe:

   - macOS (Terminal):
     ```
     defaults write com.adobe.CSXS.9 PlayerDebugMode 1
     defaults write com.adobe.CSXS.10 PlayerDebugMode 1
     defaults write com.adobe.CSXS.11 PlayerDebugMode 1
     defaults write com.adobe.CSXS.12 PlayerDebugMode 1
     ```
   - Windows (Registry Editor), under each of
     `HKEY_CURRENT_USER\Software\Adobe\CSXS.9` … `CSXS.12`, add a string
     value `PlayerDebugMode` set to `1` (create the key if it's missing).

2. **Copy this folder** into the CEP extensions directory (keep the
   `ae-auto-captions` folder name):

   - macOS: `~/Library/Application Support/Adobe/CEP/extensions/`
   - Windows: `%APPDATA%\Adobe\CEP\extensions\`

3. Restart After Effects, then open it from
   **Window → Extensions → Auto Captions**.

## Usage

1. Paste your OpenAI API key into the panel (kept only in local browser
   storage on your machine, never committed or sent anywhere but OpenAI).
2. In After Effects, select a footage layer (video or audio, must have a
   file on disk) inside a composition.
3. Click **Use Selected Layer**.
4. Pick a caption style (single word vs. short phrase) and styling
   options, then click **Transcribe**.
5. Review the transcript preview, then click **Apply Captions to
   Timeline** to generate the text layers.

## Known limitations

- OpenAI's transcription endpoint caps uploads at 25MB — trim or
  compress longer clips first.
- Assumes the layer's timeline start corresponds to the start of the
  source file (no in/out-point trim compensation yet).
- Caption layers are centered boxes you can restyle afterwards like any
  normal text layer.
- Requires an internet connection and a funded OpenAI API key.
