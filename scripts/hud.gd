extends CanvasLayer
## hud.gd — Heads-Up Display
##
## Listens to player signals (health_changed, ammo_changed, player_died)
## and updates the UI accordingly.  Requires no manual wiring — it finds
## the player automatically via the "player" group.

# ═══════════════════════════════════════════════════════════════════
# NODE REFERENCES — must match the hud.tscn structure
# ═══════════════════════════════════════════════════════════════════
@onready var health_bar: ProgressBar = $Panel/VBox/HealthBar
@onready var health_label: Label     = $Panel/VBox/HealthLabel
@onready var ammo_label: Label       = $Panel/VBox/AmmoLabel
@onready var status_label: Label     = $Panel/VBox/StatusLabel
@onready var kill_label: Label       = $Panel/VBox/KillLabel

# ═══════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════
func _ready() -> void:
	status_label.visible = false

	# Wait one frame so the player node has finished its own _ready()
	await get_tree().process_frame
	_connect_to_player()

func _process(_delta: float) -> void:
	# Live kill counter — reads from the autoload
	kill_label.text = "Kills: %d" % GameManager.kills

# ═══════════════════════════════════════════════════════════════════
# PLAYER CONNECTION
# ═══════════════════════════════════════════════════════════════════
func _connect_to_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		push_warning("HUD: No node in group 'player' found.")
		return
	var player := players[0]
	player.health_changed.connect(_on_health_changed)
	player.ammo_changed.connect(_on_ammo_changed)
	player.player_died.connect(_on_player_died)

# ═══════════════════════════════════════════════════════════════════
# SIGNAL HANDLERS
# ═══════════════════════════════════════════════════════════════════
func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = float(maximum)
	health_bar.value     = float(current)
	health_label.text    = "HP  %d / %d" % [current, maximum]
	# Flash bar red when below 30 %
	health_bar.modulate = Color.RED if current <= maximum * 0.3 else Color.WHITE

func _on_ammo_changed(current: int, maximum: int) -> void:
	ammo_label.text = "Ammo  %d / %d" % [current, maximum]
	if current == 0:
		_show_status("RELOADING…", Color(1.0, 0.8, 0.0))
	else:
		status_label.visible = false

func _on_player_died() -> void:
	_show_status("— YOU DIED —", Color.RED)

# ═══════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════
func _show_status(text: String, colour: Color) -> void:
	status_label.text     = text
	status_label.modulate = colour
	status_label.visible  = true
