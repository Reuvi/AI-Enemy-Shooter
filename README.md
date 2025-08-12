# AI-Enemy-Shooter

An enemy **NPC shooter for Roblox**. Drop it into your place and the NPC will **navigate the map and fire projectiles at players**, using Roblox pathfinding and simple, configurable combat logic.
(Core game code transfered over, project directory, assets, and exact file structure is not the same)

**Status:** Partial code drop for portfolio (not immediately runnable).
**Why:** Proprietary/large assets and project-specific file structure are excluded.

## What this shows
- Core game/logic modules I wrote
- Networking/state systems
- Key patterns: (e.g., server-authoritative actions, data-driven configs)

## What’s missing
- Assets: models, textures, audio (`/Assets`)  
- Private services / API keys  
- Full project structure (tooling/workspace files)

## Features

- **Drop-in enemy NPC** with ranged attack (projectile “bullet” model).
- **Pathfinding navigation** (`PathfindingService` via `SimplePath.lua` helper).
- **Versioned AI scripts** (`1.0.lua` → `1.9.x.lua`) showing behavior iterations.
- Ships as **Roblox models** (`.rbxm`) for quick import into Studio.

## What’s in this repo

```
/Version 1.0/
  1.0.lua ... 1.9.x.lua   # AI logic revisions (use the latest as your base)
  SimplePath.lua          # Path-following helper
/NPCExampleFolder.rbxm     # Example NPC folder (ready to drop in)
/bullet.rbxm               # Projectile model
/jediModel.rbxm            # Sample rig/model (optional)
```

## Requirements

- **Roblox Studio** (latest release recommended)

## Quick Start (Roblox Studio)

1. **Clone** or **Download ZIP** of this repository.
2. In **Roblox Studio**:

   - `File → Import…` (or drag-drop) the models you need:

     - `NPCExampleFolder.rbxm` into **Workspace**.
     - `bullet.rbxm` into **ReplicatedStorage** or **ServerStorage** (match your script’s references).

   - Copy the latest AI script from `Version 1.0/` into the NPC’s script container.
   - Ensure your place has at least one spawn location.

3. Click **Play**. The NPC should acquire a target and start engaging players in range.

> If you change where assets live (e.g., you move `bullet.rbxm`), update the references in the AI script accordingly.

## How It Works (High Level)

- **Navigation**: NPC computes a path to the current target using `PathfindingService` (via `SimplePath.lua`) and follows waypoints until within firing distance.
- **Targeting**: Default is “nearest alive player.” You can replace the targeting function to add teams, threat, or patrols.
- **Combat**: When in range/line-of-sight, the NPC spawns the projectile (`bullet.rbxm`), applies velocity, and deals damage on hit (server-authoritative).

## Configuration

Expose or tweak these values in your script/module as constants or Attributes:

- `AggroRadius` – how far the NPC notices players
- `FireRate` – seconds between shots
- `BulletSpeed` – projectile velocity
- `Damage` – damage per hit
- `MinShootDistance` / `MaxShootDistance` – effective firing envelope
- `RepathInterval` – how often to recompute a path
- `LOSCheck` – enable raycast line-of-sight checks

### Projectiles

If you replace the projectile model:

- Keep attachment/body-mover names consistent **or** update the script to match.
- Verify orientation so shots travel forward relative to the NPC.
- Consider using `FastCast` or custom raycasts for hitscan variants.

### Pathfinding Tips

- Tight indoor maps: smaller waypoint radii, more frequent LOS checks.
- Open maps: larger step spacing to reduce repath calls.
- Add a short cooldown when paths fail to avoid thrashing.

## Extending the NPC

- Add a lightweight **state machine** (PATROL → CHASE → SHOOT → RELOAD → SEARCH).
- Introduce **cover/peek** behavior and simple **flanking**.
- Add **aim spread** and difficulty-based reaction delays.
- Build a **spawn manager** for waves and difficulty presets.
- Provide **melee** variants and mixed squads.

## Suggested Folder Conventions

```
Workspace/
  NPCs/
    EnemyShooter (your NPC instance)
ReplicatedStorage/
  Assets/
    bullet (projectile model)
ServerScriptService/
  AI/
    EnemyShooter.server.lua
  Shared/
    SimplePath.lua
```

## Troubleshooting

- **NPC won’t shoot**: check LOS checks, firing range, and that the projectile is found and cloned correctly.
- **NPC stuck**: confirm `PathfindingService` can generate a path; reduce collision on the NPC rig; increase repath frequency.
- **Projectiles don’t move**: verify `BulletSpeed`, CFrame orientation, and any constraints/BodyMovers.
- **No targets**: ensure players spawn and the targeting function searches the correct container (e.g., `Players`, `Workspace` characters).

## Roadmap (Suggested)

- Cover seeking and squad behaviors
- Threat tables & focus fire
- Networked VFX and hit feedback
- Editor UI for tuning stats in Studio
- Tests for raycast/LOS and path failures

## License

Add your preferred license (e.g., MIT) or usage terms here.

## Credits

Built by **Reuvi**. Thanks to the Roblox developer community for guidance and utilities like `SimplePath`.
