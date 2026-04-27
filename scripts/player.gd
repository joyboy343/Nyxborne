extends CharacterBody2D
## player.gd — Nyxborne Player Controller
## Character: Alex, last survivor of the Malaise epidemic
##
## Controls:
##   A/D or Arrows   → Move left/right
##   Space / W       → Jump (double jump supported)
##   Left Shift      → Dash (grants i-frames)
##   Z               → Sword attack (melee)
##   X               → Shoot pistol
##   R               → Reload

# ═══════════════════════════════════════════════════════════════════
# EXPORTED STATS — tweak in the Godot Inspector
# ═══════════════════════════════════════════════════════════════════
@export_group("Movement")
@export var move_speed: float       = 200.0
@export var jump_force: float       = -420.0

@export_group("Dash")
@export var dash_speed: float       = 620.0
@export var dash_duration: float    = 0.18   # seconds of dash
@export var dash_cooldown: float    = 1.0    # seconds until next dash

@export_group("Health")
@export var max_health: int         = 100
@export var invincibility_time: float = 0.8  # i-frames after being hit

@export_group("Combat")
@export var sword_damage: int       = 25
@export var bullet_damage: int      = 15
@export var max_ammo: int           = 8
@export var reload_time: float      = 1.5

# ═══════════════════════════════════════════════════════════════════
# SIGNALS — listened to by the HUD
# ═══════════════════════════════════════════════════════════════════
signal health_changed(current: int, maximum: int)
signal ammo_changed(current: int, maximum: int)
signal player_died()

# ═══════════════════════════════════════════════════════════════════
# CONSTANTS
# ═══════════════════════════════════════════════════════════════════
const GRAVITY: float        = 980.0
const MAX_FALL_SPEED: float = 800.0
const MAX_JUMPS: int        = 2      # 1 ground jump + 1 double jump

# ═══════════════════════════════════════════════════════════════════
# INTERNAL STATE — do not edit here, managed by logic below
# ═══════════════════════════════════════════════════════════════════
var health: int
var ammo: int
var jump_count: int        = 0
var facing_right: bool     = true
var is_dashing: bool       = false
var can_dash: bool         = true
var is_invincible: bool    = false
var sword_on_cooldown: bool = false
var is_reloading: bool     = false

var _bullet_scene: PackedScene = null  # loaded at ready if file exists

# ═══════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════
func _ready() -> void:
	add_to_group("player")                   # lets enemies/HUD find us
	health = max_health
	ammo   = max_ammo

	# Wire up timer signals in code (no connection data needed in .tscn)
	$DashTimer.timeout.connect(_on_dash_timer_timeout)
	$DashCooldownTimer.timeout.connect(_on_dash_cooldown_timer_timeout)
	$ReloadTimer.timeout.connect(_on_reload_timer_timeout)
	$InvincibilityTimer.timeout.connect(_on_invincibility_timer_timeout)
	$AttackHitbox.body_entered.connect(_on_attack_hitbox_body_entered)

	# Bullet scene is optional; game still works without it
	if ResourceLoader.exists("res://scenes/bullet.tscn"):
		_bullet_scene = load("res://scenes/bullet.tscn")

	# Push initial values so the HUD shows correct numbers on start
	health_changed.emit(health, max_health)
	ammo_changed.emit(ammo, max_ammo)

func _physics_process(delta: float) -> void:
	if is_dashing:
		move_and_slide()     # dash velocity was already set; just apply it
		return

	_apply_gravity(delta)
	_handle_movement()
	_handle_jump()
	_handle_dash_input()
	move_and_slide()

	# Landed this frame → reset jump counter
	if is_on_floor():
		jump_count = 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack_sword"):
		_sword_attack()
	if event.is_action_pressed("attack_gun"):
		_shoot()
	if event.is_action_pressed("reload"):
		_start_reload()

# ═══════════════════════════════════════════════════════════════════
# MOVEMENT HELPERS
# ═══════════════════════════════════════════════════════════════════
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

func _handle_movement() -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		velocity.x = dir * move_speed
		facing_right = dir > 0.0
		# Flip the visual polygon to match direction
		if has_node("Visual"):
			$Visual.scale.x = 1.0 if facing_right else -1.0
	else:
		# Snappy stop — decelerate twice as fast as acceleration
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 2.0 * get_physics_process_delta_time())

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
		velocity.y = jump_force
		jump_count += 1

# ═══════════════════════════════════════════════════════════════════
# DASH
# ═══════════════════════════════════════════════════════════════════
func _handle_dash_input() -> void:
	if Input.is_action_just_pressed("dash") and can_dash:
		_start_dash()

func _start_dash() -> void:
	is_dashing    = true
	is_invincible = true   # i-frames during dash — untouchable!
	can_dash      = false
	var dir := 1.0 if facing_right else -1.0
	velocity       = Vector2(dir * dash_speed, 0.0)   # override vertical
	$DashTimer.start(dash_duration)
	$DashCooldownTimer.start(dash_cooldown)

func _on_dash_timer_timeout() -> void:
	is_dashing = false
	# Let gravity resume naturally; don't zero out vertical velocity

func _on_dash_cooldown_timer_timeout() -> void:
	can_dash = true

# End i-frames from dash only if the invincibility timer wasn't also
# started by a hit (whichever finishes last wins).
func _on_invincibility_timer_timeout() -> void:
	if not is_dashing:
		is_invincible = false

# ═══════════════════════════════════════════════════════════════════
# SWORD COMBAT
# ═══════════════════════════════════════════════════════════════════
func _sword_attack() -> void:
	if sword_on_cooldown:
		return
	sword_on_cooldown = true

	# Position the hitbox in front of the player
	$AttackHitbox.position.x = 30.0 if facing_right else -30.0
	$AttackHitbox.monitoring = true

	# Quick colour flash to sell the swing
	if has_node("Visual"):
		var tw := create_tween()
		tw.tween_property($Visual, "modulate", Color(1.8, 1.0, 0.4), 0.06)
		tw.tween_property($Visual, "modulate", Color.WHITE, 0.12)

	await get_tree().create_timer(0.18).timeout   # hitbox active window
	$AttackHitbox.monitoring = false
	await get_tree().create_timer(0.32).timeout   # recovery frames
	sword_on_cooldown = false

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(sword_damage)

# ═══════════════════════════════════════════════════════════════════
# GUN COMBAT
# ═══════════════════════════════════════════════════════════════════
func _shoot() -> void:
	if ammo <= 0 or is_reloading:
		if ammo == 0 and not is_reloading:
			_start_reload()    # auto-reload on empty
		return
	if _bullet_scene == null:
		push_warning("Bullet scene not found — place bullet.tscn in res://scenes/")
		return

	ammo -= 1
	ammo_changed.emit(ammo, max_ammo)

	var bullet: Node2D = _bullet_scene.instantiate()
	bullet.global_position = $GunPoint.global_position
	bullet.setup(Vector2.RIGHT if facing_right else Vector2.LEFT, bullet_damage)
	get_parent().add_child(bullet)

	if ammo == 0:
		_start_reload()

func _start_reload() -> void:
	if is_reloading or ammo == max_ammo:
		return
	is_reloading = true
	$ReloadTimer.start(reload_time)

func _on_reload_timer_timeout() -> void:
	ammo = max_ammo
	is_reloading = false
	ammo_changed.emit(ammo, max_ammo)

# ═══════════════════════════════════════════════════════════════════
# HEALTH / DAMAGE
# ═══════════════════════════════════════════════════════════════════
## Called by enemies or environmental hazards.
func take_damage(amount: int) -> void:
	if is_invincible:
		return
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	_flash_red()
	is_invincible = true
	$InvincibilityTimer.start(invincibility_time)
	if health <= 0:
		_die()

func _flash_red() -> void:
	if not has_node("Visual"):
		return
	var tw := create_tween()
	tw.tween_property($Visual, "modulate", Color.RED, 0.05)
	tw.tween_property($Visual, "modulate", Color.WHITE, 0.25)

func _die() -> void:
	player_died.emit()
	set_physics_process(false)
	set_process_unhandled_input(false)
	if has_node("Visual"):
		var tw := create_tween()
		tw.tween_property($Visual, "modulate:a", 0.0, 0.6)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
