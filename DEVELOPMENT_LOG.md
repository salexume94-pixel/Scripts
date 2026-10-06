## 2026-10-06 - Fix Enemy Action Accuracy/Critical Data

Runtime testing exposed a missing EnemyActionData field: CombatManager passes enemy action accuracy and critical-hit values into the shared CombatRules resolver, but EnemyActionData did not define those properties. This caused the Enemy Turn to fail when the AI selected an action.

Updated:
- enemies/enemy_action_data.gd
- DEVELOPMENT_LOG.md

Changes:
- Added action-level accuracy with a default of 100%.
- Added action-level critical chance with a default of 0%.
- Added action-level critical multiplier with a default of 2x.
- Existing enemy action Resources inherit these safe defaults without requiring every .tres definition to be edited immediately.
- This keeps accuracy and critical-hit data owned by EnemyActionData while CombatRules remains responsible for resolving the result.

Runtime verification required:
1. Pull the latest enemy-ai-behavior branch.
2. Start Test Battle (Enemy AI).
3. Cycle Player weakness to Water.
4. End the Player turn and confirm the Enemy Turn no longer throws the missing accuracy property error.
5. Confirm the enemy action resolves and combat returns to Player Turn.
6. Confirm no parse, resource-loading, or debugger errors occur.

Known limitation:
- Enemy accuracy and critical values now exist at the action-data layer, but enemy-specific tuning and broader runtime verification remain future work.

## 2026-10-06 - Expand Elemental Enemy AI and Player Weakness Testing

Implemented a reusable six-element test foundation so Enemy AI can evaluate and use the full elemental set against a cycling Player weakness.

Updated:
- combat/combat_rules.gd
- systems/combat_manager.gd
- combat/battle.gd
- combat/combat_state.gd
- scenes/Battle.tscn
- player/player_stats.gd
- player/definitions/player_water_weak.tres
- player/definitions/player_earth_weak.tres
- player/definitions/player_air_weak.tres
- player/definitions/player_light_weak.tres
- player/definitions/player_dark_weak.tres
- enemies/definitions/slime_water_attack.tres
- enemies/definitions/slime_earth_attack.tres
- enemies/definitions/slime_air_attack.tres
- enemies/definitions/slime_light_attack.tres
- enemies/definitions/slime_dark_attack.tres
- enemies/definitions/slime_ai_test.tres
- DEVELOPMENT_LOG.md

Changes:
- The controlled Slime AI Test now has Physical, Fire, Water, Earth, Air, Light, and Dark actions.
- Added reusable EnemyActionData definitions for Water, Earth, Air, Light, and Dark.
- Expanded the Player affinity definitions to cover Fire, Water, Earth, Air, Light, and Dark.
- The Player starts with Fire as the active elemental weakness.
- Added a Cycle Weakness control to the Battle screen. It cycles the active weakness through Fire -> Water -> Earth -> Air -> Light -> Dark.
- Player weakness cycling operates on the active CombatState copy, so the test selection does not permanently mutate the Player's saved combat state.
- Enemy AI weakness evaluation now works against all six elemental damage types through the existing behavior-profile system.
- Enemy elemental actions now resolve their actual damage against the Player's elemental affinity, so a selected attack can be verified as Weak/Normal/etc. rather than only being favored by the selector.
- Extended CombatRules with a reusable affinity-list resolution path so both Player-targeted and Enemy-targeted elemental attacks use the same affinity math.
- The combat log records the active Player weakness when it is cycled.
- Corrected the combat-log update signal so new entries are emitted immediately instead of only after the 100-entry history limit.
- Corrected the existing malformed Press Turn guard encountered while updating CombatManager.

Runtime verification required:
1. Pull the latest enemy-ai-behavior branch.
2. Start Test Battle (Enemy AI).
3. Confirm the Battle screen starts with Player Weakness: Fire.
4. Press Cycle Weakness and confirm the displayed weakness changes in the order Fire, Water, Earth, Air, Light, Dark.
5. Spend the Player turn without defeating the test enemy so the Enemy Turn occurs.
6. With each weakness selected, verify the Enemy AI favors the corresponding elemental action.
7. Confirm the selected elemental action's damage log reports Weak when it hits the matching Player weakness.
8. Confirm changing the weakness causes the AI's preferred element to change.
9. Confirm no parse, resource-loading, or debugger errors occur.
10. Confirm the normal Test Battle (Slime) encounter remains unchanged.

Known limitation:
- This is still weighted heuristic AI. It does not yet make HP-threshold, status-effect, defensive, or multi-turn tactical decisions.
- Runtime verification of the six-element cycle and cross-element AI selection is pending.

## 2026-10-06 - Enemy AI Runtime Verification Checkpoint

- Runtime testing confirmed the revised Battle presentation is substantially clearer and the current Enemy AI test flow is functioning as intended.
- Confirmed the controlled Enemy AI test uses `Slime AI Test`; no additional enemy types are implied by this work.
- Confirmed the Player's Fire weakness is visible during combat through the Player Affinities display.
- Confirmed enemy action selection is visible as `AI SELECTED: <action>` without exposing internal weighting/debug calculations in the main Battle UI.
- Confirmed the combat log tracks recent actions and keeps the newest entry visible.
- Confirmed Player and Enemy HP are clearly separated in the Battle presentation.
- Confirmed the Battle action controls remain centered in the current viewport layout.
- Confirmed the previous `systems/combat_manager.gd` indentation/parse error was corrected.
- Enemy AI still uses weighted action selection with behavior-profile modifiers and repeat-action avoidance. It is not yet a full tactical AI system.

Current Enemy AI status:
- Intelligent weighted action selection: implemented.
- Player elemental weakness consideration: implemented.
- Behavior profiles: implemented.
- Repeat-action avoidance: implemented.
- Runtime presentation/debug visibility: verified.
- Broader AI distribution/balance sampling: still recommended before treating the AI as fully balanced.

Known limitation:
- The current AI does not yet evaluate HP thresholds, status effects, defensive needs, multi-turn planning, or broader battle context.

Next development priority:
- Continue with the next item in the development roadmap after Enemy AI behavior, rather than adding unrequested enemy types or expanding the AI scope prematurely.

### Combat Dialogue Actor Clarity

Updated the Battle presentation so Player and Enemy actions are explicitly identified during runtime debugging.

Updated:
- combat/battle.gd
- systems/combat_manager.gd
- DEVELOPMENT_LOG.md

Changes:
- Player combat messages now use an explicit `PLAYER:` prefix.
- Enemy combat messages now use an explicit `ENEMY:` prefix.
- Enemy Turn start now identifies the active enemy by display name and reports that it is choosing an action.
- Enemy action results now identify both the enemy and the selected action, for example: `ENEMY: Slime uses Fire Attack for 12 damage. PLAYER TURN.`
- Added a presentation-safe CombatManager getter for the active enemy display name so Battle does not resolve enemy definitions directly.
- This keeps enemy selection logic in CombatManager while making Enemy AI runtime verification unambiguous.

Runtime verification required:
- Pull the latest `enemy-ai-behavior` branch.
- Start Test Battle (Enemy AI).
- Confirm the dialogue clearly distinguishes PLAYER and ENEMY actions.
- Confirm Enemy Turn displays the active enemy name.
- Confirm the selected enemy action name is visible after the Enemy Turn resolves.
- Confirm no parse, resource-loading, or debugger errors occur.

### Enemy AI / Behavior
Implemented the Enemy AI behavior layer for action selection.

Updated:
- enemies/enemy_behavior_profile.gd
- enemies/definitions/behavior_balanced.tres
- enemies/definitions/behavior_weakness_hunter.tres
- enemies/enemy_data.gd
- systems/combat_manager.gd
- enemies/enemy_database.gd
- enemies/definitions/slime_fire_attack.tres
- enemies/definitions/slime_ai_test.tres
- ui/inventory_character_hud.gd
- ui/InventoryCharacterHUD.tscn
- DEVELOPMENT_LOG.md

Changes:
- Enemy action selection is now weighted instead of always selecting the first action.
- EnemyData can optionally assign an EnemyBehaviorProfile. Enemies without a profile use the shared Balanced profile.
- Added Balanced, Aggressive, and Weakness Hunter behavior strategies.
- Aggressive behavior increases the relative priority of stronger actions.
- Weakness Hunter behavior increases the priority of actions whose damage type matches a known Player Weak affinity.
- Enemy AI avoids Player Resist, Null, Drain, and Repel reactions when the assigned behavior profile is configured to do so.
- Player affinities are captured when an encounter starts, before the Battle scene replaces the World scene, and stored in CombatState for the duration of the encounter.
- Added a controlled slime_ai_test enemy with Physical and Fire actions using the Weakness Hunter profile.
- Added a Fire action to the AI test encounter so the Player's existing Fire weakness can be used to verify elemental-aware enemy selection.
- Added a DEBUG entry point labeled Test Battle (Enemy AI) without changing the normal Slime encounter definition.
- Battle presentation continues to report the selected enemy action through the existing CombatManager state, keeping selection logic out of the UI.

Runtime/debug verification:
- Static repository verification completed: the AI test encounter is registered, its behavior profile is assigned, its Fire action uses Fire damage, and the Player's default Fire Weak affinity is captured into CombatState at encounter start.
- The controlled test encounter weights the Fire action above the Physical actions when the Player is Fire Weak, while retaining weighted random selection.
- Local Godot runtime verification is still required. GitHub repository inspection cannot execute the Godot project.
- Runtime checklist:
  1. Pull enemy-ai-behavior.
  2. Open the Character/Inventory DEBUG panel.
  3. Start Test Battle (Enemy AI).
  4. Spend four Player Press Turns without defeating the test enemy.
  5. Confirm the Enemy Turn selects and displays an enemy action.
  6. Repeat the encounter enough times to confirm Fire Attack is strongly favored while the Player is Fire Weak.
  7. Confirm no parse, resource-loading, or debugger errors occur.
  8. Confirm the normal Test Battle (Slime) encounter remains unchanged.

Known limitation:
- Enemy AI currently selects an action using weighted heuristics only. It does not yet account for HP thresholds, status effects, defensive needs, multi-turn planning, or battle context beyond Player elemental affinity.
- Runtime verification must be performed in the local Godot project before this task can be marked fully runtime-verified.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of each major section.

### Combat Critical Test and Victory UI Corrections

Corrected two runtime issues found during Critical/Accuracy verification.

Updated:
- combat/battle.gd
- scenes/Battle.tscn
- DEVELOPMENT_LOG.md

Changes:
- Critical results are now displayed before the victory message, so a critical hit that reduces the enemy to 0 HP is still explicitly reported as CRITICAL.
- Restored the Critical Test and Miss Test Button nodes and their signal connections in Battle.tscn. The scene previously contained signal connections to missing nodes.
- Restored the intended Battle UI path for testing critical and miss behavior.
- The existing Return to World victory control remains responsible for leaving a completed battle.

Runtime verification required:
- Pull the latest combat-elemental-affinities branch.
- Start a Slime battle and use Critical Test.
- Confirm the ActionLabel explicitly says CRITICAL, including when the critical hit defeats the enemy.
- Confirm the Critical Test consumes 0.5 Press Turns when the enemy survives.
- Confirm Miss Test remains available and reports MISS.
- Reduce the enemy to 0 HP and confirm Return to World is visible and exits the battle without requiring Run.
- Confirm no Godot debugger errors occur.

Known limitation:
- Critical/accuracy behavior is still Player-focused. Enemy accuracy, enemy critical hits, evasion, and final accuracy formulas remain future work.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of each major section.

### Combat Critical Hits and Accuracy: Initial Implementation

Implemented the first accuracy and critical-hit layer for Player combat actions.

Added:
- combat/definitions/critical_test.tres
- combat/definitions/miss_test.tres

Updated:
- combat/player_action_data.gd
- combat/combat_rules.gd
- combat/combat_state.gd
- systems/combat_manager.gd
- combat/battle.gd
- scenes/Battle.tscn
- DEVELOPMENT_LOG.md

Changes:
- PlayerActionData now supports action accuracy, critical chance, and critical damage multiplier.
- CombatRules now resolves accuracy before affinity.
- Misses deal 0 damage, leave both HP pools unchanged, and consume 1 full Press Turn.
- Critical hits currently double the resolved damage and consume 0.5 Press Turns.
- Critical hits are resolved after affinity so Weak and Critical can combine.
- CombatState records whether the most recent Player action was critical.
- Battle UI displays explicit MISS and CRITICAL results.
- Added deterministic Critical Test and Miss Test actions so runtime verification does not depend on random chance.
- Existing Physical, Fire, Weak, Resist, Null, Drain, Repel, Defend, Pass, Run, Victory, and Enemy Turn behavior remains routed through the existing combat architecture.

Runtime verification required:
- Pull the latest `combat-elemental-affinities` branch.
- Confirm the project opens without parse or resource errors.
- Start a normal Slime battle.
- Use Critical Test and confirm damage is exactly 2x the normal Physical damage.
- Confirm Critical Test consumes 0.5 Press Turns.
- Confirm the Battle UI explicitly reports CRITICAL.
- Use Miss Test and confirm enemy HP is unchanged.
- Confirm Player HP is unchanged after a miss.
- Confirm Miss Test consumes 1 full Press Turn.
- Confirm the Battle UI explicitly reports MISS.
- Confirm normal Attack and Fire still behave correctly.
- Confirm no Godot debugger errors occur.

Known limitation:
- Accuracy and critical values are currently action-level data and Player-focused.
- Enemy accuracy, enemy critical hits, evasion stats, and final accuracy formulas remain future work.
- Critical behavior is intentionally isolated for runtime verification before expanding the rules.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of each major section.

### Combat Affinity: Repel Implementation

Implemented the Fire Repel affinity as the final affinity in the current elemental foundation.

Added:
- enemies/definitions/slime_fire_repel.tres
- enemies/definitions/slime_repel.tres

Updated:
- enemies/enemy_database.gd
- ui/inventory_character_hud.gd
- ui/InventoryCharacterHUD.tscn
- DEVELOPMENT_LOG.md

Changes:
- Added a controlled Fire Repel enemy definition without changing the existing affinity test enemies.
- Registered `slime_repel` in EnemyDatabase.
- Added a DEBUG entry labeled `Test Battle (Fire Repel)`.
- Existing CombatRules Repel behavior remains authoritative: resolved Fire damage is reflected back to the Player while the target takes no damage.
- Repel testing is isolated from the other affinity tests.
- Repel currently uses the standard 1 Press Turn cost until runtime behavior is verified and any intended cost correction is identified.

Runtime verification required:
- Pull the latest `combat-elemental-affinities` branch.
- Confirm `Test Battle (Fire Repel)` appears in DEBUG.
- Start the Fire Repel encounter without parse, resource, or debugger errors.
- Use Fire against the Repel Slime.
- Confirm the Repel Slime's HP is unchanged.
- Confirm the Player takes the reflected damage.
- Confirm the reflected damage matches the resolved Fire damage.
- Confirm the Player's Press Turns decrease by 1 full turn.
- Confirm combat continues normally after the reflected attack.
- Confirm no Godot debugger errors occur.

Known limitation:
- Runtime verification is pending.
- Critical hits and accuracy remain the next combat rules layer.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of each major section.

### Combat Affinity: Drain Press Turn Cost Correction

Updated Drain after runtime verification confirmed its healing behavior was correct but its Press Turn cost was not.

Updated:
- combat/combat_rules.gd
- DEVELOPMENT_LOG.md

Changes:
- Drain still converts the resolved damage into healing for the target.
- Healing remains capped at the target's maximum HP.
- Drain now consumes all 4 Press Turns.
- No Battle UI or enemy-definition changes were needed because Press Turn cost belongs in CombatRules.

Runtime verification required:
- Start Test Battle (Fire Drain).
- Lower the Drain Slime below maximum HP.
- Use Fire and confirm the enemy heals by the resolved amount.
- Confirm enemy HP does not exceed maximum HP.
- Confirm all 4 Press Turns are depleted.
- Confirm Enemy Turn begins when Drain resolves.
- Confirm Player HP is unchanged by Drain.
- Confirm existing Weak, Normal, Resist, and Null behavior remains unchanged.
- Confirm no Godot debugger errors occur.

### Combat Affinity: Drain Implementation

Implemented the Fire Drain affinity as the next elemental combat step.

Added:
- enemies/definitions/slime_fire_drain.tres
- enemies/definitions/slime_drain.tres

Updated:
- enemies/enemy_database.gd
- ui/inventory_character_hud.gd
- ui/InventoryCharacterHUD.tscn
- DEVELOPMENT_LOG.md

Changes:
- Added a controlled Fire Drain enemy definition without changing the existing affinity test enemies.
- Registered `slime_drain` in EnemyDatabase.
- Added a DEBUG entry labeled `Test Battle (Fire Drain)`.
- Existing CombatRules Drain behavior remains authoritative: the resolved Fire damage becomes healing for the target, capped at maximum HP, and consumes 1 full Press Turn.
- Drain testing is isolated from the other affinity tests.

Runtime verification required:
- Pull the latest `combat-elemental-affinities` branch.
- Confirm `Test Battle (Fire Drain)` appears in DEBUG.
- Start the Fire Drain encounter without parse, resource, or debugger errors.
- Use Physical Attack first to lower the Drain Slime below maximum HP.
- Use Fire and confirm the enemy HP increases by the resolved Fire damage amount.
- Confirm enemy HP cannot exceed maximum HP.
- Confirm Fire Drain consumes exactly 1 full Press Turn.
- Confirm the Player takes no damage from Drain.
- Confirm combat continues normally.
- Confirm existing Weak, Normal, Resist, and Null tests remain unchanged.
- Confirm no Godot debugger errors occur.

Known limitation:
- Runtime verification is pending.
- Repel remains after Drain.

### Combat Affinity: Null Press Turn Cost Correction

Updated Null after runtime verification.

Updated:
- combat/combat_rules.gd
- DEVELOPMENT_LOG.md

Changes:
- Nullification still deals 0 damage and leaves enemy HP unchanged.
- Nullification now consumes 2 full Press Turns instead of 1.
- Weak remains 0.5 Press Turns.
- Normal remains 1 Press Turn.
- Resist remains 1 Press Turn.

Runtime verification required:
- Start Test Battle (Fire Null).
- Confirm Fire deals 0 damage.
- Confirm enemy HP is unchanged.
- Confirm exactly 2 full Press Turns are consumed.
- Confirm combat continues normally.
- Confirm existing Weak, Normal, and Resist behavior remains unchanged.
- Confirm no Godot debugger errors occur.

### Combat Affinity: Null Implementation

Implemented the Fire Null affinity as the next elemental combat step.

Added:
- enemies/definitions/slime_fire_null.tres
- enemies/definitions/slime_null.tres

Updated:
- enemies/enemy_database.gd
- ui/inventory_character_hud.gd
- ui/InventoryCharacterHUD.tscn
- DEVELOPMENT_LOG.md

Changes:
- Added a controlled Fire Null enemy definition without changing the existing Weak or Resist test enemies.
- Registered `slime_null` in EnemyDatabase.
- Added a DEBUG entry labeled `Test Battle (Fire Null)`.
- Existing CombatRules Nullify behavior remains authoritative: Fire damage is reduced to 0 and consumes one full Press Turn.
- Null testing is isolated from the other affinity tests.

Runtime verification required:
- Pull the latest `combat-elemental-affinities` branch.
- Confirm `Test Battle (Fire Null)` appears in DEBUG.
- Start the Fire Null encounter without parse, resource, or debugger errors.
- Use Fire and confirm damage is exactly 0.
- Confirm Enemy HP does not change.
- Confirm exactly one full Press Turn is consumed.
- Confirm combat continues normally after the nullified attack.
- Confirm existing Weak and Resist tests remain unchanged.
- Confirm no Godot debugger errors occur.

Known limitation:
- Null has been implemented and provided a controlled runtime test encounter, but runtime verification is pending.
- Drain and Repel remain after Null.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of each major section.

### Combat Affinity: Resist Implementation

Implemented the Fire Resist affinity as the next elemental combat step.

Added:
- enemies/definitions/slime_fire_resist.tres
- enemies/definitions/slime_resist.tres

Updated:
- enemies/enemy_database.gd
- ui/inventory_character_hud.gd
- ui/InventoryCharacterHUD.tscn
- DEVELOPMENT_LOG.md

Changes:
- Added a controlled Fire Resist enemy definition without changing the existing Slime's Fire Weak behavior.
- Registered `slime_resist` in EnemyDatabase so CombatManager can resolve it through the authoritative enemy catalog.
- Added a DEBUG entry point labeled `Test Battle (Fire Resist)`.
- The existing CombatRules Resist behavior remains authoritative: Fire damage is reduced to 0.5x and consumes one full Press Turn.
- Kept Resist testing separate from the normal Fire Weak test so both affinity behaviors can be verified independently.
- No runtime verification has been claimed yet.

Runtime verification required:
- Pull the latest `combat-elemental-affinities` branch.
- Open the Character/Inventory DEBUG panel.
- Confirm `Test Battle (Fire Resist)` appears.
- Start the Fire Resist encounter without debugger/parse/resource errors.
- Confirm Fire against Resist deals exactly 0.5x the Player Attack damage.
- Confirm the Fire Resist action consumes exactly one full Press Turn.
- Confirm the enemy remains alive and combat continues normally.
- Confirm the existing Fire Weak Slime test still reports Weak, 1.5x damage, and 0.5 Press Turn.
- Confirm no Godot debugger errors occur.

Known limitation:
- Resist has been implemented and provided a controlled runtime test encounter, but runtime verification is still pending.
- Null, Drain, and Repel remain the next affinity implementations/tests.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of each major section.

### Player Fire Action for Elemental Runtime Testing

Added the first real elemental Player action so the Slime's Fire weakness can be runtime verified.

Created:
- `combat/player_action_data.gd`
- `combat/definitions/physical_attack.tres`
- `combat/definitions/fire_attack.tres`

Updated:
- `systems/combat_manager.gd`
- `combat/battle.gd`
- `scenes/Battle.tscn`
- `DEVELOPMENT_LOG.md`

Changes:
- Added PlayerActionData as a reusable Resource for Player combat actions.
- Player actions now define an action ID, display name, damage type, and Attack-stat power multiplier.
- Moved the existing basic Physical Attack into a Physical Player action Resource.
- Added a Fire Player action using the Player's Attack stat at 1.0x power.
- Added a Fire button to the Battle UI.
- Both Physical Attack and Fire use the same CombatManager and CombatRules resolution path.
- The Slime's existing Fire Weak affinity can now be exercised through the Battle UI.
- Existing Defend, Pass, Run, Victory, Enemy Turn, and Press Turn behavior remains unchanged.
- This establishes the data-driven path needed for future elemental skills without hardcoding individual attacks into Battle.

Runtime verification required:
- Pull the `combat-elemental-affinities` branch.
- Confirm the project starts without parse or resource-loading errors.
- Start Test Battle (Slime).
- Confirm both Attack and Fire are available during Player Turn.
- Press Fire and confirm the Battle reports Fire / Weak.
- Confirm Fire deals 1.5x the Player Attack value against the Slime.
- Confirm Fire consumes exactly 0.5 Press Turns, leaving three full turns and one half turn after the first Fire action.
- Confirm another Fire action can consume the remaining half turn and correctly exhaust the Player's Press Turns.
- Confirm the enemy turn still resolves correctly after Press Turns are exhausted.
- Confirm Physical Attack still reports Physical / Normal and consumes 1 full Press Turn.
- Confirm no Godot debugger errors occur.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.


### Elemental Damage Types and Enemy Affinities

Started the elemental combat foundation for the Press Turn system.

Created:
- `combat/damage_types.gd`
- `combat/affinities.gd`
- `combat/combat_rules.gd`
- `enemies/enemy_affinity_data.gd`
- `enemies/definitions/slime_fire_weak.tres`

Updated:
- `enemies/enemy_action_data.gd`
- `enemies/enemy_data.gd`
- `enemies/definitions/slime_attack.tres`
- `enemies/definitions/slime_heavy_attack.tres`
- `enemies/definitions/slime.tres`
- `combat/combat_state.gd`
- `systems/combat_manager.gd`
- `combat/battle.gd`
- `DEVELOPMENT_LOG.md`

Changes:
- Added the shared damage types: Physical, Fire, Water, Earth, Air, Light, and Dark.
- EnemyActionData now records the damage type of each action. Existing Slime attacks are explicitly Physical.
- Added enemy affinity data with Normal, Weak, Resist, Null, Drain, and Repel states.
- EnemyData now owns a list of affinity definitions. Damage types without a configured affinity default to Normal.
- Added a reusable CombatRules layer for affinity resolution instead of placing combat math in Battle or enemy Resources.
- Weak currently increases damage to 1.5x and consumes 0.5 Press Turns.
- Normal currently deals normal damage and consumes 1 Press Turn.
- Resist currently reduces damage to 0.5x and consumes 1 Press Turn.
- Null currently prevents damage.
- Drain currently heals the target by the resolved amount.
- Repel currently reflects the resolved damage to the attacker.
- The Player's existing basic Attack now resolves through the enemy affinity system and defaults to Physical damage.
- Player attacks now consume the Press Turn cost returned by the affinity result, allowing Weak attacks to leave a half Press Turn.
- Battle UI now reports the damage type and affinity result for Player attacks.
- Added a Fire Weakness to the Slime as the first concrete enemy affinity definition. The current basic Player Attack remains Physical, so this weakness is ready for future elemental Player actions without changing the current test battle's normal Physical behavior.
- Critical hits, accuracy/evasion, misses, and advanced Press Turn outcomes are intentionally not implemented yet.
- Enemy AI behavior remains the next major combat layer after elemental/affinity math is runtime verified.

Runtime verification required:
- Pull the `combat-elemental-affinities` branch.
- Confirm the project opens without parse errors.
- Start Debug -> Test Battle (Slime).
- Confirm the normal Physical Player Attack still deals its expected normal damage.
- Confirm the Battle action text identifies the attack as Physical / Normal.
- Confirm Press Turns still decrement correctly for a normal attack.
- Confirm the Slime's Fire Weak affinity is loaded without Resource or parse errors.
- Confirm the Battle scene displays correctly after combat.
- Confirm no Godot debugger errors occur.
- Future test: add a temporary Fire Player action and confirm Fire -> Weak produces increased damage and consumes only half a Press Turn.
- Future tests should also cover Resist, Null, Drain, and Repel individually before adding critical-hit and accuracy systems.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.


### Player Defend and Pass Actions

Added two Player-turn actions to the Press Turn combat system.

Updated:
- `combat/combat_state.gd`
- `systems/combat_manager.gd`
- `combat/battle.gd`
- `scenes/Battle.tscn`
- `DEVELOPMENT_LOG.md`

Changes:
- Added **Defend** as a full-turn Player action.
- Defend marks the Player as defending and reduces the next enemy turn's final damage by 50%, with a minimum of 1.
- Defend is cleared after the enemy attack, so it does not persist into later rounds.
- Added **Pass** as a full-turn Player action.
- Pass consumes one Press Turn without changing HP, stats, or enemy state.
- Both actions use the existing Press Turn exhaustion flow, so spending the fourth action starts the Enemy Turn.
- Added Defend and Pass buttons to the Battle UI.
- Existing Attack, Run, Victory, Enemy Action Selection, and Press Turn behavior remains unchanged.

Runtime verification required:
- Pull the latest main branch.
- Start Test Battle (Slime).
- Confirm Attack, Defend, Pass, and Run are available during Player Turn.
- Confirm Defend consumes exactly one Press Turn.
- Confirm Defend reduces the next enemy damage by 50% and then clears.
- Confirm Pass consumes exactly one Press Turn and does not change HP.
- Confirm using Defend or Pass as the fourth action starts Enemy Turn.
- Confirm both actions remain unavailable during Enemy Turn and Victory/Defeat.
- Confirm no Godot debugger errors occur.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.

### Combat Testing Adjustment: Slime Test HP

Adjusted the Slime's test HP so the new enemy action-selection system can be exercised across multiple enemy turns.

Updated:
- `enemies/definitions/slime.tres`
- `DEVELOPMENT_LOG.md`

Changes:
- Increased Slime maximum HP from 50 to 100.
- This is a testing adjustment so the current Player Attack value does not defeat the Slime immediately after the first enemy turn.
- Enemy action selection, Press Turn behavior, damage formulas, and Player stats were not changed.
- The Slime can now survive multiple Player/Enemy turn cycles, making repeated action selection observable in one encounter.

Runtime verification required:
- Pull the latest main branch.
- Start Test Battle (Slime).
- Confirm Enemy HP starts at 100 / 100.
- Confirm four Player Attacks trigger the first Enemy Turn.
- Confirm the selected action is displayed.
- Continue the battle and confirm additional Enemy Turns can occur.
- Confirm both Attack and Heavy Attack can be observed over repeated enemy turns.
- Confirm existing damage, Press Turn, Victory, and Run behavior remains functional.
- Confirm no Godot debugger errors occur.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.

### Enemy Action Selection: Multiple Slime Actions

Expanded the enemy action foundation so the Slime now has two selectable actions.

Created:
- `enemies/definitions/slime_heavy_attack.tres`

Updated:
- `enemies/definitions/slime_attack.tres`
- `enemies/definitions/slime.tres`
- `DEVELOPMENT_LOG.md`

Changes:
- Kept the existing Slime `Attack` at power 10 and selection weight 1.
- Added `Heavy Attack` at power 14 and selection weight 1.
- Registered both actions in the Slime's EnemyData action list.
- The existing weighted selection system now has two valid actions to choose from.
- With the current Player Defense value of 10, Attack deals 1 damage while Heavy Attack deals 4 damage.
- Slime HP remains 50, so the established combat test values are unchanged.
- No elemental behavior, status effects, conditional AI, or new turn rules were added.

Runtime verification required:
- Pull the latest main branch.
- Confirm the project opens without parse errors.
- Start Test Battle (Slime).
- Spend all four Player Press Turns without defeating the Slime.
- Confirm the enemy turn resolves without errors.
- Confirm the Battle action text identifies the selected action.
- Repeat the test across multiple battles and confirm both `Attack` and `Heavy Attack` can be selected.
- Confirm Attack deals 1 damage and Heavy Attack deals 4 damage under the current Player Defense calculation.
- Confirm Press Turns, Victory, and Run remain functional.
- Confirm no Godot debugger errors occur.

Known limitation:
- The current selection is weighted random, so either action may be selected on a given enemy turn.
- The Slime only receives one enemy turn before its 50 HP is normally depleted by the current Player Attack value.
- Conditional behavior and true enemy AI remain future work.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.

### Enemy Action Selection Foundation

Implemented the first action-selection layer for enemies.

Updated:
- `enemies/enemy_action_data.gd`
- `combat/combat_state.gd`
- `systems/combat_manager.gd`
- `combat/battle.gd`
- `DEVELOPMENT_LOG.md`

Changes:
- Added a configurable `selection_weight` to EnemyActionData.
- CombatManager now selects an enemy action using weighted random selection rather than always taking the first action.
- Actions with a weight of 0 are ignored by normal selection.
- CombatState records the ID and display name of the action selected for the current enemy turn.
- Battle UI now reports the selected enemy action name when the enemy attacks.
- The Slime currently has only one action, so its runtime behavior and 10-power attack remain unchanged.
- Existing Player Defense damage calculation, Press Turns, Victory, Run, and defeat behavior remain unchanged.

This establishes the foundation for enemies with multiple actions without moving action-selection rules into the Battle UI or EnemyData resources.

Runtime verification required:
- Pull the latest main branch.
- Confirm the project opens without parse errors.
- Start Debug -> Test Battle (Slime).
- Spend all four Player Press Turns without defeating the Slime.
- Confirm the enemy turn resolves normally.
- Confirm the Battle result identifies the action as `Attack`.
- Confirm the Slime still deals 1 damage under the current Player Defense calculation.
- Confirm combat returns to PLAYER TURN with four Press Turns.
- Confirm Victory and Run still work.
- Confirm no Godot debugger errors occur.

Known limitation:
- The Slime currently has only one action, so weighted selection cannot yet demonstrate different choices.
- Enemy AI is not implemented. Weighted selection is only the reusable selection mechanism.
- Action effects, elemental types, accuracy, status effects, and conditional behavior remain future work.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.

### Enemy Action Foundation

Implemented the first enemy-action layer on top of the authoritative EnemyData foundation.

Created:
- `enemies/enemy_action_data.gd`
- `enemies/definitions/slime_attack.tres`

Updated:
- `enemies/enemy_data.gd`
- `enemies/definitions/slime.tres`
- `systems/combat_manager.gd`

Changes:
- Added EnemyActionData as a separate Resource for individual enemy actions.
- EnemyData now contains an action list instead of requiring CombatManager to know which attack an enemy uses.
- Added the Slime's first action, `slime_attack`, with display name `Attack` and power 10.
- CombatManager now requires the enemy to have at least one defined action before starting an encounter.
- The current enemy turn uses the first action in the enemy's action list.
- The existing Player Defense calculation and minimum 1 damage rule are unchanged.
- Existing Press Turn, Victory, Run, and defeat-state behavior remain unchanged.

This establishes the separation:

`EnemyData -> EnemyActionData -> CombatManager -> CombatState`

The current system still intentionally uses only the first action. Action selection and enemy AI will be added later after this foundation is runtime verified.

Runtime verification required:
- Pull the latest main branch.
- Confirm the project opens without parse errors.
- Start Debug -> Test Battle (Slime).
- Confirm the Slime battle still starts at 50 / 50 HP.
- Spend all four Player Press Turns without defeating the Slime.
- Confirm the Slime still attacks once for 1 damage under the current Player Defense calculation.
- Confirm combat returns to PLAYER TURN with four Press Turns.
- Confirm Victory and Run still work.
- Confirm no Godot debugger errors occur.

Known limitation:
- EnemyActionData currently contains only an action ID, display name, and physical power.
- CombatManager currently executes the first action rather than selecting between multiple actions.
- Elemental types, costs, accuracy, effects, and enemy AI remain future work.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.

### Chest Implementation and Runtime Verification

Implemented and runtime verified the reusable World Chest.

Created:
- `world/chest.gd`
- `world/Chest.tscn`

The Chest owns its physical presence, interaction range, open/closed state, and temporary visual state. It does not own item definitions or inventory storage.

The Chest uses the **E key** while the Player is within interaction range. A shared interaction input/UI system remains intentionally separate.

The Chest was runtime tested successfully:
- The Chest is visible.
- The Chest physically blocks the Player.
- The interaction range detects the Player.
- Pressing **E** in range opens the Chest.
- Pressing **E** outside the range does nothing.
- An opened Chest cannot be opened repeatedly.
- The Chest changes visual state when opened.
- Player movement, Building collision, Door transition, and World boundaries remain functional.
- Godot reported no script errors during the item reward test.

The Chest body collision was increased from `32x24` to `40x32` to prevent visible Player overlap.

### Building Collision

The World Building exterior collision has been corrected and runtime verified.

The previous collision layout used oversized wall rectangles that overlapped around the Building corners. This could push the Player away from the Building or prevent the Player from walking completely around it.

Updated:
- `world/building.gd`

The corrected collision layout:
- Keeps the Building's visible footprint unchanged.
- Uses clean wall geometry around the exterior.
- Prevents problematic collision overlap at the corners.
- Keeps the bottom wall split around the Door.
- Preserves the intended visual clearance between the Player and Building.
- Includes comments explaining the purpose and geometry of each collision section.

Runtime verification confirmed the Player can walk completely around the Building without the previous pushing or corner-blocking behavior.

### Item and Inventory Foundation

Implemented the first functional Item and Player Inventory foundation.

Created:
- `items/item_data.gd`
- `items/test_items.gd`

Updated:
- `player/player_inventory.gd`
- `world/chest.gd`

`ItemData` defines the shared data structure for an item, including:
- Stable item ID.
- Display name.
- Description.
- Category.
- Maximum stack size.

`TestItems` provides temporary Potion, Sword, and Gold definitions for development and testing.

`PlayerInventory` stores item quantities by item ID and supports:
- Adding items.
- Removing items.
- Checking item quantities.
- Checking whether the Player owns a requested quantity.
- Enforcing item stack limits.
- Providing a read-only inventory copy through `get_inventory()`.

The Chest now creates a test item reward and adds it to the Player's inventory when opened.

Godot initially reported parse errors because the inventory and Chest scripts depended on globally registered `class_name` types. Those dependencies were replaced with explicit script preloads so the item systems do not depend on Godot's global class-name cache being available at parse time.

### Inventory Runtime Verification

The Chest-to-inventory path has now been runtime verified.

The temporary debug inventory display was replaced by the reusable **Inventory/Character HUD**.

Created:
- `systems/game_state.gd`
- `ui/inventory_character_hud.gd`
- `ui/InventoryCharacterHUD.tscn`

Updated:
- `player/player_inventory.gd`
- `project.godot`
- `scenes/World.tscn`
- `scenes/Interior.tscn`

Removed:
- `world/debug_inventory_ui.gd`

The new HUD:
- Is a reusable CanvasLayer scene.
- Is available in both World and Building Interior.
- Opens and closes with the **I key**.
- Reads inventory through `PlayerInventory.get_inventory()`.
- Displays readable names for the current temporary test items.
- Does not own or modify inventory data.

### Inventory Runtime Persistence

`GameState` is now an autoload responsible for the runtime inventory snapshot.

The persistence path is now:

`Chest -> PlayerInventory -> GameState`

When a scene transition recreates the Player:
- The new PlayerInventory loads its inventory from GameState.
- Successful inventory additions/removals synchronize back to GameState.
- Inventory therefore has a runtime owner outside the Player scene.

This is **runtime persistence only**. It does not yet save inventory to disk. Save/load persistence will remain the responsibility of the future save system.

### Four Inventory/HUD Tasks

The four previously identified tasks have now been started:

1. **Build the real Inventory/Character screen HUD**
   - Initial reusable HUD implemented.

2. **Make the HUD available from the appropriate game UI context**
   - The same HUD scene is instantiated in both World and Interior instead of being tied only to World.

3. **Replace the temporary debug inventory display**
   - The temporary debug UI has been removed and replaced by the new HUD.

4. **Establish a persistence owner for inventory**
   - GameState now owns the runtime inventory snapshot so it survives Player recreation during scene transitions.

### Current Verification Status

The new HUD and GameState changes have **not yet been runtime tested locally** after the GitHub implementation.

The next required runtime test should verify:
- Project opens without parse errors.
- World loads normally.
- Pressing **I** opens the Character/Inventory screen.
- Inventory starts empty.
- Chest still awards `Test Potion`.
- HUD displays `Test Potion x1`.
- Entering the Building Interior keeps the inventory.
- Pressing **I** inside the Interior opens the same HUD.
- Returning to the World keeps the inventory.
- No Godot debugger errors occur.

### Current Project State

Verified before this change:
- World scene and camera.
- Player movement and collision.
- World boundaries.
- Building exterior collision.
- Building Door and Interior transition.
- Chest presence, collision, and E-key interaction.
- Item data foundation.
- Test item definitions.
- Functional Player inventory storage.
- Read-only inventory interface.
- Chest item rewards.
- Chest-to-inventory runtime verification.

Implemented but awaiting local runtime verification:
- Inventory/Character screen HUD.
- HUD availability in World and Interior.
- Replacement of temporary inventory debug UI.
- Runtime inventory persistence through GameState.

Still incomplete:
- Disk save/load persistence.
- Full character stats/equipment presentation.
- Equipment system integration.
- Shared interaction/input system.
- Item use/consumption behavior.
- Item detail/selection UI.
- Quests and other planned World systems.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.


### Character Screen and Inventory UI Expansion

Implemented the next three Inventory/Character HUD tasks:

1. Character stats section
   - The HUD now reads Player level, HP, MP, Attack, Defense, Magic Attack, Magic Defense, and Speed directly from PlayerStats.
   - The HUD does not duplicate or own stat values.

2. Inventory slot UI
   - The previous text-only inventory list was replaced with selectable inventory slots.
   - Each owned item is represented by a button showing its readable name and quantity.
   - Inventory data remains owned by PlayerInventory.

3. Item selection and details
   - Selecting an inventory slot updates a details panel with the item's name, description, and quantity.
   - Selection is UI state only.
   - Item use, consumption, equipping, and other item behavior remain separate future systems.

Updated:
- ui/inventory_character_hud.gd
- ui/InventoryCharacterHUD.tscn

### Current Runtime Verification Required

The new Character/Inventory UI has not yet been runtime tested after this implementation.

Verify locally:
- Project opens without parse errors.
- World loads normally.
- Pressing I opens the expanded Character/Inventory screen.
- Character stats display the current PlayerStats values.
- Inventory starts empty.
- Chest still awards Test Potion.
- Test Potion x1 appears as a selectable inventory slot.
- Selecting the potion shows its name, description, and quantity.
- Entering the Interior preserves the inventory and HUD behavior.
- Returning to World preserves the inventory and HUD behavior.
- No Godot debugger errors occur.

Continue using comments in scripts to explain each script and major section.


### Character HUD Movement Lock

Updated the Character/Inventory HUD so opening it disables Player movement while the screen is visible.

Updated:
- player/player_movement.gd
- ui/inventory_character_hud.gd

The movement system now exposes a small `set_movement_enabled()` control point. The HUD uses that control instead of directly manipulating CharacterBody2D movement. Existing velocity is cleared immediately when the HUD opens so the Player cannot continue sliding.

Runtime verification required:
- Open the Character/Inventory HUD with **I**.
- Confirm directional input no longer moves the Player.
- Confirm the Player stops immediately when the HUD opens.
- Close the HUD with **I** and confirm movement resumes normally.
- Confirm World/Interior transitions and inventory behavior remain unchanged.


### Item Behavior, Use, and Equipment Foundation

Implemented the first functional item behavior layer while preserving the one-primary-job architecture.

Updated:
- items/item_data.gd
- items/test_items.gd
- player/player_stats.gd
- player/player_equipment.gd
- systems/game_state.gd
- ui/inventory_character_hud.gd
- ui/InventoryCharacterHUD.tscn

Created:
- systems/item_use_system.gd

ItemData now defines behavior data for consumables, equipment, currency, materials, and a future key-item category. It also carries consumable HP/MP restoration values and equipment slot/stat bonus data.

Test item behavior:
- Test Potion restores 25 HP and consumes exactly one item when it has an effect.
- Test Sword is weapon equipment with +5 Attack.
- Test Gold is a currency item and is not treated as a consumable.

Ownership responsibilities remain separated:
- ItemData = item definition and behavior data.
- PlayerInventory = item quantities.
- PlayerEquipment = equipped item ownership and equipment changes.
- PlayerStats = resulting HP/MP and combat stat values.
- ItemUseSystem = applies consumable effects.
- InventoryCharacterHUD = displays state and requests actions.

Equipment is transferred from inventory to PlayerEquipment while equipped and returned to inventory when unequipped. GameState keeps the equipped-item snapshot through scene transitions, and a newly created Player reapplies stored equipment modifiers to PlayerStats.

The HUD now provides Use for consumables, Equip for equipment, current weapon display, weapon unequip, and immediate stat refresh after actions.

### Runtime Verification Required: Item Behavior

Run locally after pulling the latest commits:
- Project opens without parse errors.
- Open the Character/Inventory HUD.
- Reduce Player HP before using Test Potion.
- Select Test Potion and press Use.
- Confirm HP increases by 25, one potion is removed, and an empty stack disappears.
- Attempt to use a potion at full HP and confirm it is not consumed.
- Obtain Test Sword, select it, and press Equip.
- Confirm the sword leaves inventory, Weapon displays Test Sword, and Attack increases from 10 to 15.
- Press Unequip Weapon and confirm the sword returns to inventory and Attack returns to 10.
- Transition World -> Interior -> World and confirm equipped state and resulting stats persist.
- Confirm no Godot debugger errors occur.


### Test Item Access and HUD Interaction Fix

Updated the temporary item test path so the item systems can actually be exercised in runtime.

Updated:
- world/chest.gd
- world/Chest.tscn
- scenes/World.tscn
- scenes/Interior.tscn
- ui/inventory_character_hud.gd
- ui/InventoryCharacterHUD.tscn

Changes:
- Chest rewards are now selected by exported item ID instead of every chest always giving Test Potion.
- World now contains separate Test Potion and Test Sword chests.
- Interior now also contains separate Test Potion and Test Sword chests.
- The Character/Inventory HUD no longer rebuilds its inventory Buttons every frame. The previous per-frame rebuild could destroy a Button while it was being clicked, making the UI effectively non-interactive.
- The HUD Screen now accepts mouse input while its background remains mouse-transparent, allowing child Buttons to receive clicks.
- The HUD still locks Player movement while open.

Runtime verification required:
- Pull the commit and open the project.
- Open the HUD with I and click an inventory item.
- Confirm the item details and Use/Equip button respond to mouse clicks.
- Obtain Test Potion from a Potion Chest.
- Obtain Test Sword from a Sword Chest.
- Equip and unequip the sword and verify Attack changes 10 -> 15 -> 10.
- Verify the potion can be selected and its Use button is clickable.
- Verify the same test item access exists in World and Interior.
- Confirm no Godot debugger errors.


### Item Testing Control

Added a temporary development control to the Character HUD so the Test Potion can be verified before the full combat system exists.

Updated:
- player/player_stats.gd
- ui/inventory_character_hud.gd
- ui/InventoryCharacterHUD.tscn

The HUD now has a **Test Damage (-25 HP)** button that calls PlayerStats.take_damage(). This is explicitly a development test control and is not intended to become the final combat UI.

This allows the item loop to be tested now:
1. Obtain Test Potion from a Potion Chest.
2. Open the Character/Inventory HUD.
3. Press Test Damage (-25 HP).
4. Select Test Potion.
5. Press Use.
6. Confirm HP increases by 25 and one potion is consumed.


### Item Behavior Runtime Verification

The item behavior loop has now been runtime verified locally.

Verified:
- Test Potion can be picked up from a Potion Chest.
- Test Potion quantities stack correctly from `x1` to `x2`.
- Test Sword can be picked up when the inventory does not already contain one.
- A second Test Sword cannot be picked up when the existing sword has reached its `max_stack_size` of 1.
- Test Sword can be equipped from the Character/Inventory HUD.
- Test Sword can be unequipped and returned to the inventory.
- Equipment changes therefore correctly move the item between PlayerInventory and PlayerEquipment.

The verified item path is now:

`Chest -> ItemData -> PlayerInventory -> HUD -> PlayerEquipment -> PlayerStats`

### Debug System Separation

The temporary Test Damage control has been moved into the project's debug architecture.

Created:
- `systems/debug_system.gd`

Updated:
- `ui/inventory_character_hud.gd`
- `ui/InventoryCharacterHUD.tscn`

Architecture:
- `DebugSystem` owns development-only test actions.
- `InventoryCharacterHUD` presents the debug control and requests the action.
- `PlayerStats` remains responsible for applying the resulting damage.
- The Test Damage control is now grouped under a dedicated **DEBUG** section in the Character HUD.
- The debug control is only visible in Godot debug builds.

This keeps development/testing behavior out of the normal Character HUD logic while preserving the ability to damage the Player for potion testing.

Runtime verification required after this change:
- Pull the latest commits.
- Open the Character HUD in a debug build.
- Confirm the **DEBUG** section contains Test Damage.
- Press Test Damage and confirm HP decreases by 25.
- Use Test Potion and confirm HP is restored by 25 and one potion is consumed.
- Confirm no Godot debugger errors occur.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.


### Item System Foundation: Resource Definitions

Replaced the temporary in-code item catalog with actual ItemData Resource definitions.

Created:
- `items/item_database.gd`
- `items/definitions/potion.tres`
- `items/definitions/iron_sword.tres`
- `items/definitions/wooden_shield.tres`
- `items/definitions/leather_helm.tres`
- `items/definitions/leather_armor.tres`
- `items/definitions/power_ring.tres`
- `items/definitions/gold.tres`

Updated:
- `items/item_data.gd`
- `world/chest.gd`
- `scenes/World.tscn`
- `scenes/Interior.tscn`

Removed:
- `items/test_items.gd`

ItemData now has typed equipment slots:
- Weapon
- Shield
- Head
- Body
- Accessory

ItemDatabase is now the authoritative mapping from stable item IDs to shared Resource definitions. Inventory, equipment, HUD, item use, and Chest systems no longer need to construct temporary item definitions in code.

### Inventory and Equipment Expansion

Updated:
- `player/player_equipment.gd`
- `ui/inventory_character_hud.gd`
- `ui/InventoryCharacterHUD.tscn`

Equipment now supports multiple slots with one item per slot:

## 2026-10-06 Enemy AI Weakness Selection Ratio

- Updated the weakness-hunter behavior profile so weakness-targeting decisions use an explicit **66.67% selection chance**.
- The remaining **33.33%** selects from non-weakness actions, preserving the intended behavior of approximately 2 weakness attacks for every 1 other attack over a large sample.
- Individual sequences remain random, so a short run may produce patterns such as `EARTH, EARTH, WATER` or `EARTH, WATER, EARTH`.
- Updated files:
  - `enemies/enemy_behavior_profile.gd`
  - `enemies/definitions/behavior_weakness_hunter.tres`
  - `systems/combat_manager.gd`
- Runtime verification required: start **Test Battle (Enemy AI)**, set the Player weakness, allow many Enemy turns, and confirm the matching elemental action occurs roughly 2/3 of the time while other valid actions occur roughly 1/3 of the time.
