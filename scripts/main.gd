extends Node2D
## main.gd — Ashen Hollow (Test Level)
##
## Level geometry is created procedurally so the project runs without
## any tileset assets.  Add your TileMap later and delete _build_level().

# ─── Colour palette (Ashen Hollow dark-gritty theme) ──────────────
const COL_GROUND    := Color(0.20, 0.18, 0.22)   # near-black ground
const COL_PLATFORM  := Color(0.28, 0.24, 0.32)   # dark purple platform
const COL_ACCENT    := Color(0.38, 0.30, 0.42)   # slightly lighter ledge

# ─── Platform layout: [center_x, center_y, width, height, colour] ─
const PLATFORMS := [
	# Ground slab (intentionally very wide)
	[0,    520, 2400, 48, COL_GROUND],

	# Mid platforms — form a rough ascent to the right
	[-340, 360, 210, 22, COL_PLATFORM],
	[-80,  280, 170, 22, COL_PLATFORM],
	[ 180, 200, 150, 22, COL_ACCENT],
	[ 380, 300, 200, 22, COL_PLATFORM],
	[ 560, 180, 130, 22, COL_ACCENT],

	# High ledge on the left
	[-540, 250, 160, 22, COL_PLATFORM],
	[-700, 160, 120, 22, COL_ACCENT],

	# Ceiling / upper-right area
	[ 750, 120, 180, 22, COL_PLATFORM],
]

func _ready() -> void:
	_build_level()
	_setup_world_bounds()

# ═══════════════════════════════════════════════════════════════════
# LEVEL BUILDING
# ═══════════════════════════════════════════════════════════════════
func _build_level() -> void:
	for data in PLATFORMS:
		_spawn_platform(data[0], data[1], data[2], data[3], data[4])

func _spawn_platform(cx: float, cy: float, w: float, h: float, colour: Color) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(cx, cy)

	# Collision
	var col   := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	col.shape  = shape
	body.add_child(col)

	# Visual (Polygon2D — no texture required)
	var poly := Polygon2D.new()
	var hw   := w * 0.5
	var hh   := h * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw,   hh), Vector2(-hw, hh),
	])
	poly.color = colour
	body.add_child(poly)

	$World.add_child(body)

# ─── Invisible kill-plane below the level ─────────────────────────
func _setup_world_bounds() -> void:
	var kill_plane := Area2D.new()
	kill_plane.position = Vector2(0, 800)

	var kshape := CollisionShape2D.new()
	var krect  := RectangleShape2D.new()
	krect.size = Vector2(4000, 40)
	kshape.shape = krect
	kill_plane.add_child(kshape)
	kill_plane.body_entered.connect(_on_kill_plane_entered)
	add_child(kill_plane)

func _on_kill_plane_entered(body: Node2D) -> void:
	# Anything that falls off the map takes lethal damage
	if body.has_method("take_damage"):
		body.take_damage(9999)
