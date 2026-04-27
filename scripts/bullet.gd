extends Area2D
## bullet.gd — Pistol Projectile
##
## Usage (called automatically from player.gd):
##   var b := bullet_scene.instantiate()
##   b.global_position = gun_point.global_position
##   b.setup(direction, damage)
##   parent.add_child(b)

@export var speed: float   = 520.0
@export var lifetime: float = 2.0    # auto-destroy after this many seconds

var direction: Vector2 = Vector2.RIGHT
var damage: int = 15

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Auto-destroy so stray bullets don't pile up
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

## Set direction and damage before adding to the scene tree.
func setup(dir: Vector2, dmg: int) -> void:
	direction = dir.normalized()
	damage    = dmg
	# Rotate the visual to point in the travel direction
	rotation = direction.angle()

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif body is StaticBody2D:
		# Hit a wall / floor — destroy bullet
		queue_free()
