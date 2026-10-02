# Development Log

## 2026-10-02

### Project Initialization

Started a fresh Godot 4.7 project named **Scripts** using the **Compatibility** renderer and Git version control.

The project is being rebuilt from scratch with a stronger separation of responsibilities than the previous Prototype project.

### Initial Structure

Created the following top-level directories:

- `combat/`
- `data/`
- `enemies/`
- `items/`
- `player/`
- `quests/`
- `scenes/`
- `systems/`
- `ui/`
- `world/`

### Architecture

Created `ARCHITECTURE.md` to establish project organization and separation-of-responsibility rules.

Core principle:

> A script should do one primary job.

Player systems will be separated instead of placing movement, stats, skills, inventory, equipment, and other unrelated functionality into one large player script.

### Systems Created

Created `systems/game_manager.gd`.

Created the initial Player scene:

`scenes/player.tscn`

The Player root is a `CharacterBody2D`.

Created `player/player.gd` as the Player's core script.

Created `player/player_movement.gd` for movement logic.

The Player scene currently contains:

- `Player`
- `PlayerMovement`
- `PlayerSprite`
- `PlayerCollision`

A temporary `CircleShape2D` collision shape was added to `PlayerCollision`.

### Current Status

The project is still in the foundation stage.

Movement has been implemented but has not yet been meaningfully tested because the project does not yet have a test world.

### Next Work

- Finish verifying the Player collision setup.
- Create a minimal test world.
- Test Player movement and collision.
- Continue separating Player systems such as stats, skills, inventory, equipment, and progression.
