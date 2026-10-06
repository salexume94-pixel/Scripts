### Combat and Development Roadmap

The next development phase is the game's combat foundation, followed by the enemy system, progression, save/load persistence, and broader World/quest expansion.

### 1. Combat Foundation

Build the actual combat system next.

Planned combat foundation:
- Combat encounter/state system.
- Player attack.
- Enemy HP.
- Damage calculation.
- Player defense.
- Defeat/death handling.
- Return from battle to the World.
- Combat UI.

The intended core gameplay loop is:

`Explore -> encounter enemy -> fight -> win/lose -> return to World`

### 2. Enemy Foundation

After the combat foundation is established, build the enemy system that combat uses.

Planned enemy foundation:
- `EnemyData`.
- Enemy stats.
- Enemy definitions.
- Enemy instances.
- Basic enemy behavior.
- XP/reward data.

### 3. Progression

Once combat can produce rewards, implement progression systems.

Planned progression:
- XP.
- Leveling.
- Stat growth.
- Gold.
- Loot.

### 4. Save/Load

After the runtime GameState and gameplay systems are stable, implement persistent save/load.

Planned save/load data:
- Save GameState to disk.
- Load GameState from disk.
- Player position and current scene.
- Inventory.
- Equipment.
- Player stats.
- World/chest state.

The existing GameState remains runtime persistence only until this phase. Disk persistence should be implemented as a separate save/load responsibility rather than turning GameState into a file-management system.

### 5. Quests and World Expansion

After the core combat, enemy, progression, and save systems are established, expand the World and quest structure.

Planned World expansion:
- Quest system.
- Quest log.
- NPCs.
- Gated areas.
- More buildings.
- More interactables.

### Development Priority

The current implementation priority is:

`Combat Foundation -> Enemy Foundation -> Progression -> Save/Load -> Quests and World Expansion`

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.
