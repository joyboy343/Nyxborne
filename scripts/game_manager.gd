extends Node
## game_manager.gd — Global Singleton (Autoload)
##
## Handles:
##   • Pause / unpause
##   • Kill counter (to track progression)
##   • Scene transition helpers
##
## Access from any script: GameManager.register_kill()

# ═══════════════════════════════════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════════════════════════════════
signal game_paused(is_paused: bool)

# ═══════════════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════════════
var is_paused: bool = false
var kills: int      = 0

# ═══════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════
func _ready() -> void:
	# Always process even when game is paused (so we can unpause)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

# ═══════════════════════════════════════════════════════════════════
# PAUSE
# ═══════════════════════════════════════════════════════════════════
func toggle_pause() -> void:
	is_paused            = not is_paused
	get_tree().paused    = is_paused
	game_paused.emit(is_paused)

# ═══════════════════════════════════════════════════════════════════
# PROGRESSION
# ═══════════════════════════════════════════════════════════════════
func register_kill() -> void:
	kills += 1
	print("[GameManager] Enemy killed. Total kills: %d" % kills)

# ═══════════════════════════════════════════════════════════════════
# SCENE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════
func load_level(scene_path: String) -> void:
	kills = 0
	get_tree().change_scene_to_file(scene_path)

func restart() -> void:
	is_paused         = false
	get_tree().paused = false
	kills             = 0
	get_tree().reload_current_scene()
