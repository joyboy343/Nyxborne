extends CharacterBody2D
## enemy.gd — Nyxborne Enemy AI
##
## Behaviour:
##   1. PATROL  — walks between patrol_left_x and patrol_right_x
##   2. ALERT   — player enters DetectionRange → chase and attack
##   3. RETURN  — player leaves range → return to patrol bounds
##
## To place a new enemy:
##   • Instance enemy.tscn in your level scene
##   • Set patrol_left_x / patrol_right_x in the Inspector
##     (these are LOCAL X offsets from the enemy's starting position)

# ═══════════════════════════════════════════════════════════════════
# EXPORTED SETTINGS
# ═══════════════════════════════════════════════════════════════════
@export_group("Stats")
@export var max_health: int        = 50
@export var contact_damage: int    = 10   # damage dealt per hit

@export_group("Movement")
@export var patrol_speed: float    = 70.0
@export var chase_speed: float     = 120.0
@export var patrol_left_x: float   = -120.0   # local X offset left
@export var patrol_right_x: float  = 120.0    # local X offset right

@export_group("Attack")
@export var attack_range: float    = 48.0    # melee range in pixels
@export var attack_cooldown: float = 1.2

# ═══════════════════════════════════════════════════════════════════
# INTERNAL STATE
# ═══════════════════════════════════════════════════════════════════
const GRAVITY: float = 980.0

enum State { PATROL, CHASE, ATTACK }

var health: int
var state: State = State.PATROL
var patrol_origin: float             # world-space X recorded at spawn
var patrol_dir: int = 1              # 1 = right, -1 = left
var tracked_player: Node2D = null
var can_attack: bool = true

# ═══════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════
func _ready() -> void:
	add_to_group("enemies")
	health        = max_health
	patrol_origin = global_position.x   # remember spawn X for patrol bounds

	$DetectionRange.body_entered.connect(_on_detection_entered)
	$DetectionRange.body_exited.connect(_on_detection_exited)
	$AttackHitbox.body_entered.connect(_on_attack_hitbox_body_entered)
	$AttackTimer.timeout.connect(_on_attack_timer_timeout)

func _physics_process(delta: float) -> void:
	# Always apply gravity so enemy stays on platforms
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, 800.0)

	match state:
		State.PATROL:  _tick_patrol()
		State.CHASE:   _tick_chase()
		State.ATTACK:  velocity.x = 0.0   # stand still while attacking

	move_and_slide()
	_update_facing()

# ═══════════════════════════════════════════════════════════════════
# PATROL LOGIC
# ═══════════════════════════════════════════════════════════════════
func _tick_patrol() -> void:
	velocity.x = patrol_dir * patrol_speed

	var left_bound  := patrol_origin + patrol_left_x
	var right_bound := patrol_origin + patrol_right_x

	# Reverse direction at patrol bounds
	if global_position.x >= right_bound:
		patrol_dir = -1
	elif global_position.x <= left_bound:
		patrol_dir = 1

# ═══════════════════════════════════════════════════════════════════
# CHASE LOGIC
# ═══════════════════════════════════════════════════════════════════
func _tick_chase() -> void:
	if tracked_player == null:
		state = State.PATROL
		return

	var dist := global_position.distance_to(tracked_player.global_position)

	if dist <= attack_range:
		state = State.ATTACK
		_try_attack()
	else:
		var dir := sign(tracked_player.global_position.x - global_position.x)
		velocity.x = dir * chase_speed

# ═══════════════════════════════════════════════════════════════════
# ATTACK LOGIC
# ═══════════════════════════════════════════════════════════════════
func _try_attack() -> void:
	if not can_attack:
		return
	can_attack = false
	$AttackHitbox.monitoring = true
	$AttackTimer.start(attack_cooldown)

	# Brief visual flash to signal the attack wind-up
	if has_node("Visual"):
		var tw := create_tween()
		tw.tween_property($Visual, "modulate", Color(1.5, 0.3, 0.3), 0.05)
		tw.tween_property($Visual, "modulate", Color.WHITE, 0.15)

	await get_tree().create_timer(0.3).timeout
	$AttackHitbox.monitoring = false

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(contact_damage)

func _on_attack_timer_timeout() -> void:
	can_attack = true
	# If player is still in range, stay in ATTACK; otherwise chase
	if tracked_player != null:
		var dist := global_position.distance_to(tracked_player.global_position)
		state = State.ATTACK if dist <= attack_range else State.CHASE
	else:
		state = State.PATROL

# ═══════════════════════════════════════════════════════════════════
# DETECTION RANGE CALLBACKS
# ═══════════════════════════════════════════════════════════════════
func _on_detection_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		tracked_player = body
		state          = State.CHASE

func _on_detection_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		tracked_player = null
		state          = State.PATROL   # lose aggro

# ═══════════════════════════════════════════════════════════════════
# DAMAGE / DEATH
# ═══════════════════════════════════════════════════════════════════
## Called by player's sword or bullet.
func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	_flash_hit()

	# Getting hurt makes a patrolling enemy alert immediately
	if state == State.PATROL and tracked_player != null:
		state = State.CHASE

	if health <= 0:
		_die()

func _flash_hit() -> void:
	if not has_node("Visual"):
		return
	var tw := create_tween()
	tw.tween_property($Visual, "modulate", Color(2.0, 0.4, 0.4), 0.04)
	tw.tween_property($Visual, "modulate", Color.WHITE, 0.12)

func _die() -> void:
	if GameManager:
		GameManager.register_kill()
	# Fade out and free
	if has_node("Visual"):
		var tw := create_tween()
		tw.tween_property($Visual, "modulate:a", 0.0, 0.3)
		await tw.finished
	queue_free()

# ═══════════════════════════════════════════════════════════════════
# VISUAL
# ═══════════════════════════════════════════════════════════════════
func _update_facing() -> void:
	if not has_node("Visual"):
		return
	if velocity.x > 0.5:
		$Visual.scale.x = 1.0
	elif velocity.x < -0.5:
		$Visual.scale.x = -1.0
