# 🌑 Nyxborne

> *"They called it the Malaise. By the time they had a name for it, there was almost no one left to speak it."*

A dark, gritty 2D RPG Platformer built in **Godot 4.3** — inspired by Dead Cells.
You play as **Alex**, the last survivor of the Malaise epidemic, fighting through interconnected regions of a dying world.

---

## 🎮 Controls

| Key | Action |
|-----|--------|
| `A` / `D` or `← →` | Move left / right |
| `Space` / `W` / `↑` | Jump |
| `Space` / `W` (air) | Double jump |
| `Left Shift` | Dash (grants i-frames) |
| `Z` | Sword attack (melee) |
| `X` | Shoot pistol |
| `R` | Reload |
| `E` | Interact (placeholder) |
| `Escape` | Pause |

---

## 🚀 How to Run

### Requirements
- **Godot 4.3** — [Download here](https://godotengine.org/download) (use the stable release, not Mono)

### Steps
1. Clone or download this repository
2. Open **Godot 4.3**
3. Click **"Import"** → navigate to the `nyxborne/` folder → select `project.godot`
4. Click **"Import & Edit"**
5. Press **F5** (or the ▶ button) to run

> **No external assets needed.** The prototype uses procedurally generated placeholder visuals (coloured polygons) so it runs out of the box.
>
> To add your own sprites, replace the `Polygon2D` nodes in the scenes with `Sprite2D` nodes and assign your textures in the Inspector.

---

## 📁 Project Structure

```
nyxborne/
├── project.godot          ← Godot project config + input map
├── icon.svg               ← Project icon
├── .gitignore
├── README.md
│
├── scripts/
│   ├── player.gd          ← Player movement, dash, sword, pistol
│   ├── enemy.gd           ← Enemy AI: patrol → chase → attack
│   ├── bullet.gd          ← Pistol projectile
│   ├── main.gd            ← Procedural level generation
│   ├── hud.gd             ← UI: health bar, ammo counter, status
│   └── game_manager.gd    ← Autoload: pause, kill count, scene control
│
├── scenes/
│   ├── main.tscn          ← 🎯 Main scene (run this)
│   ├── player.tscn        ← Alex + camera + timers + hitboxes
│   ├── enemy.tscn         ← Enemy + detection range + attack area
│   ├── bullet.tscn        ← Pistol projectile
│   └── levels/            ← (future levels go here)
│
├── ui/
│   └── hud.tscn           ← HP bar, ammo label, status text
│
└── assets/
    ├── sprites/           ← Drop your sprite sheets here
    └── effects/           ← Particle textures, etc.
```

---

## ⚔️ Implemented Systems

### Player (Alex)
- ✅ Walk / run with snappy deceleration
- ✅ Double jump (configurable max jumps)
- ✅ Dash with **invincibility frames** (i-frames)
- ✅ Sword attack with active hitbox window
- ✅ Pistol with ammo count + auto/manual reload
- ✅ Health system with hit flash + i-frames
- ✅ Death → auto-restart after 2 seconds

### Enemy AI
- ✅ Patrol between two configurable bounds
- ✅ Detection radius — switches to chase on player proximity
- ✅ Melee attack with cooldown
- ✅ Takes damage from sword and bullets
- ✅ Kill registered in GameManager

### World
- ✅ Procedurally generated platform layout (Ashen Hollow test level)
- ✅ Kill-plane — lethal fall damage
- ✅ Camera with position smoothing

### UI / HUD
- ✅ Health bar (turns red below 30%)
- ✅ Ammo counter
- ✅ "RELOADING…" and "YOU DIED" status messages
- ✅ Kill counter

---

## 🗺️ Planned Regions

| Region | Status |
|--------|--------|
| Ashen Hollow | ✅ Prototype layout |
| Vermillion Grove | 🔲 Planned |
| The Forsaken Labyrinth | 🔲 Planned |
| Sunken Archives | 🔲 Planned |
| Iron Wastes | 🔲 Planned |

---

## 🔧 Future Improvements

### Next Steps (recommended order)
1. **Sprite integration** — replace Polygon2D visuals with AnimatedSprite2D + your sprite sheets
2. **AnimationPlayer** — add idle/run/jump/attack animations
3. **Sound effects** — footsteps, sword swing, gunshot, hit
4. **TileMap level** — build Ashen Hollow with proper tiles
5. **Enemy variety** — ranged enemy (shoots back), flying enemy
6. **Loot / items** — health pickups, ammo drops
7. **Checkpoint system** — save spawn points between rooms
8. **Room transitions** — door triggers that load the next region
9. **Player stats UI** — dash cooldown indicator, stamina bar
10. **Blood splatter particles** — CPUParticles2D on enemy death

### Engine Features to Explore
- `AnimationTree` for blended animations
- `NavigationAgent2D` for smarter enemy pathfinding
- `ShaderMaterial` for the dark/gritty pixel art look
- `AudioStreamPlayer` with bus routing for spatial sound

---

## 🛠️ Customisation Tips

**Changing player stats** — select the Player node in `main.tscn` and edit exported variables in the Inspector:
- `move_speed`, `jump_force`, `dash_speed`, `max_health`, `max_ammo`, etc.

**Adjusting enemy patrol** — select an Enemy node, set `patrol_left_x` / `patrol_right_x` (local X offset from spawn position).

**Adding a new enemy** — duplicate `Enemy1` in the `Enemies` node of `main.tscn`, reposition, adjust patrol bounds.

**Adding a new level** — create a new scene inheriting `Node2D`, add a `World` node, instance `player.tscn` and `hud.tscn`, call `get_tree().change_scene_to_file("res://scenes/levels/your_level.tscn")` from `game_manager.gd`.

---

## 📜 Lore Snippet

> The Malaise swept through the five regions in forty-three days.
> Cities that had stood for centuries dissolved into ash and rust.
> Alex doesn't know if there's a cure. Doesn't know if there's anything left worth curing.
> But the Labyrinth holds answers — and monsters.

---

*Built with ❤️ and Godot 4.3*
