# Scripts - Architecture

## Purpose

This project is a fresh implementation of the game systems from the previous prototype.

The goal is to keep systems organized, modular, and easy to understand.

Each script should have a clear responsibility.

---

## Core Rule

A script should do one primary job.

A system should not contain unrelated functionality simply because it is convenient.

If a script becomes responsible for multiple unrelated systems, the functionality should be separated into additional scripts.

---

## Project Structure

### combat/

Combat-related systems.

Examples:
- Battle management
- Combat actions
- Damage calculation
- Player combat
- Enemy combat

### data/

Reusable game data definitions.

Examples:
- Item data
- Enemy data
- Skill data
- Equipment data

Data definitions should not contain large amounts of unrelated gameplay logic.

### enemies/

Enemy-specific behavior.

Examples:
- Enemy controllers
- Enemy behavior
- Enemy decision-making
- Enemy-specific mechanics

### items/

Item-related systems.

Examples:
- Item behavior
- Item usage
- Item effects

### player/

Player-related systems.

Examples:
- Player core
- Movement
- Stats
- Skills
- Inventory
- Equipment
- Progression

Player systems should not contain unrelated world, UI, or save-system logic.

### quests/

Quest-related systems.

Examples:
- Quest definitions
- Quest tracking
- Quest objectives
- Quest rewards

### scenes/

Game scenes.

Examples:
- Main scene
- Player scene
- World scenes
- Battle scenes
- Test scenes

### systems/

Global game systems.

Examples:
- Game manager
- Save/load manager
- Scene management
- Global state

### ui/

User interface systems.

Examples:
- Menus
- HUD
- Inventory interface
- Character interface
- Battle interface

UI scripts should handle presentation and user interaction rather than owning the underlying game data.

### world/

World-related systems.

Examples:
- World interaction
- Doors
- Chests
- Regions
- Waystones
- World objects

---

## Separation of Responsibilities

Game logic should remain separate from UI whenever practical.

Game data should remain separate from presentation.

Saving and loading should be handled by the save system rather than individual gameplay systems.

Global systems should coordinate other systems rather than replacing them.

---

## Player Architecture

The player will be divided into focused systems.

Expected systems include:

- Player core
- Player movement
- Player stats
- Player skills
- Player inventory
- Player equipment
- Player progression

These systems may communicate with each other, but each should maintain a clearly defined responsibility.

---

## Development Rule

Do not add functionality to an existing script merely because the functionality is related to the same object.

First determine which system owns the responsibility.

---

## Reference Project

The previous Prototype project may be used as a reference for existing gameplay mechanics.

Its architecture should not be copied automatically.

Existing mechanics should be redesigned and implemented according to this architecture.