### Equipment Save / Load Regression: Runtime Verification Passed

Fixed and verified a Save / Load regression where equipped equipment was lost after loading a saved game.

Root cause:
- Equipment is stored in GameState using integer equipment-slot enum keys.
- JSON serialization converts Dictionary keys to strings.
- PlayerEquipment was validating the loaded string key directly against the integer equipment-slot enum.
- The saved equipment item therefore remained in the save data but was rejected during restoration.

Updated:
- player/player_equipment.gd
- DEVELOPMENT_LOG.md

Changes:
- Convert saved equipment slot keys back to integers during PlayerEquipment restoration.
- Preserve the existing stable item-ID equipment architecture.
- Keep equipment stat modifiers reapplied when the equipped item is restored.
- No save-file version change was required, so existing version-1 saves remain compatible.

Runtime verification passed:
- Equipped equipment remains equipped after saving and restarting the game.
- Equipped equipment persists when loading the saved game.
- Equipped equipment stat modifiers remain applied after loading.
- The church save NPC dialogue displays correctly.
- No Save / Load or equipment persistence errors were reported during verification.

The Save / Load foundation is now verified for inventory, equipment, stats, level/XP, HP/MP, gold, quest state, chest state, scene, and Player position/context.

Next:
- Main Menu runtime verification: New Game, Load, and Quit at game startup.
