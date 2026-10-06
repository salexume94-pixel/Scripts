# Enemy AI

## Purpose

Enemy AI is profile-driven. Enemy definitions provide available actions, behavior profiles describe how those actions should be prioritized, and `CombatManager` applies the selected action during combat.

The system is designed so new enemy types can reuse the same AI framework without adding enemy-specific branches to `CombatManager`.

## Responsibilities

### EnemyData

`enemies/enemy_data.gd` defines an enemy's shared gameplay data.

It owns:
- Enemy identity and display name
- Base stats
- Available actions
- Optional behavior profile
- Elemental affinities
- Rewards

It does not decide which action is selected.

### EnemyActionData

`enemies/enemy_action_data.gd` defines one available enemy action.

It owns:
- Action identity
- Display name
- Power
- Damage type
- Selection weight
- Weakness weight multiplier
- Accuracy
- Critical-hit data

It does not decide when the action is used.

### EnemyBehaviorProfile

`enemies/enemy_behavior_profile.gd` defines AI preferences.

Current strategies:
- `BALANCED`
- `AGGRESSIVE`
- `WEAKNESS_HUNTER`
- `DEFENSIVE`

Profiles are Resources, so different enemy definitions can use different behavior without changing combat code.

### CombatManager

`systems/combat_manager.gd` owns the active encounter and performs action selection.

The selector:
1. Reads the enemy's behavior profile.
2. Calculates a weight for each usable action.
3. Applies strategy-specific modifiers.
4. Avoids configured unfavorable affinities.
5. Discourages immediate action repetition.
6. Performs weighted random selection.
7. Uses a safe fallback if profile modifiers eliminate every weighted candidate.

CombatManager does not contain enemy-specific behavior.

## Current Profiles

### Balanced

Uses the configured action weights with only the shared affinity and repeat-action modifiers.

Use this for enemies that do not need a strong tactical preference.

### Aggressive

Favors higher-power actions.

The strongest available action can receive up to twice its base selection weight, while weaker actions retain a chance to be selected.

### Weakness Hunter

Uses a configurable probability to choose between the Player-weakness action pool and the non-weakness action pool.

The current test profile uses `0.65`, approximately 13 weakness selections out of 20 over a sufficiently large sample.

This is probabilistic, not an exact 13-of-20 scheduler.

### Defensive

Favors lower-power actions and rejects unfavorable elemental reactions when the profile is configured to do so.

The current implementation treats lower-power actions as the safer choice. This provides a defensive behavior foundation without requiring defensive skills to exist yet.

Future defensive actions can be added to `EnemyActionData` and incorporated into the same profile system without creating a separate AI architecture.

## Edge-Case Handling

Enemy AI must never leave an encounter permanently stuck on Enemy Turn because an action could not be selected.

Current safeguards include:
- Empty action lists return no action safely.
- Invalid or zero-weight configurations are handled without crashing.
- If profile modifiers eliminate every weighted candidate but at least one usable action exists, the selector falls back to the first usable action.
- If no valid action exists at all, CombatManager logs the condition, skips the Enemy Turn, restores Player Turn, and restores the Player's Press Turns.

## Test Encounters

The repository contains controlled Slime AI test definitions using the same eight-action set:

- `slime_ai_test`: Weakness Hunter
- `slime_ai_balanced_test`: Balanced
- `slime_ai_aggressive_test`: Aggressive
- `slime_ai_defensive_test`: Defensive

These are test configurations, not additional gameplay enemy types.

The debug Character/Inventory HUD exposes the four behavior tests.

## Runtime Verification

### Weakness Hunter

Run multiple 20-turn samples.

The current target is approximately 13 weakness selections per 20 turns, while allowing normal random variation.

Also change the Player's weakness during combat and confirm the preferred action changes with it.

### Balanced

Run enough Enemy Turns to confirm the available actions are broadly selected according to their configured weights.

### Aggressive

Run enough Enemy Turns to confirm stronger actions, especially Heavy Attack, occur more frequently than in the Balanced profile.

### Defensive

Run enough Enemy Turns to confirm lower-power actions occur more frequently than Heavy Attack and unfavorable elemental reactions are avoided.

### Shared Framework

Confirm all profiles:
- Use the same `EnemyData` structure.
- Use the same `EnemyActionData` structure.
- Use the same CombatManager selector.
- Require no enemy-specific AI code.

### Edge Cases

Verify:
1. An enemy with no actions does not leave combat stuck.
2. An enemy with all actions at zero selection weight does not leave combat stuck.
3. A profile that rejects every weighted candidate falls back to a usable action.
4. An enemy without a behavior profile uses the shared Balanced profile.
5. Changing the Player's weakness does not require changing the enemy behavior profile.

## Design Boundary

The current AI is intentionally action-selection AI, not a complete tactical planner.

It does not yet evaluate:
- Player HP thresholds
- Enemy HP thresholds
- Status effects
- Party composition
- Multi-turn planning
- Support priorities
- Boss-specific phases

Those systems should be added only when the combat design requires them.

## Architectural Rule

Future enemies should normally be created by combining:

`EnemyData + EnemyActionData + EnemyBehaviorProfile`

rather than adding enemy-specific selection logic to `CombatManager`.

This keeps the AI reusable as the enemy roster grows.