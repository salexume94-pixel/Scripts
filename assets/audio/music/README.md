# Music Assets

Place the game's licensed/owned music tracks in this folder.

Expected filenames (case-sensitive):
- `overworld.mp3` — overworld exploration music.
- `tutorial_town.mp3` — Tutorial Town's location music.
- `battle.mp3` — combat encounter music.

The AudioManager checks whether each file exists before loading it. The project can therefore open before the MP3 files are uploaded, but the corresponding track will remain silent until its file is present.

Keep music files here. Sound effects, voice recordings, and other audio asset categories should use separate subfolders under `assets/audio/` as they are added.
