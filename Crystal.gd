extends Node3D

# COLLECTIBLE CRYSTAL.
#
# Joins the "Crystal" group at runtime so GameManager can count the total for
# the HUD. The child Area3D (collision_mask already matches the Player's
# collision_layer) reports the touch; this script just handles the pickup FX.

@export var spin_speed := 1.5
@export var bob_height := 0.35
@export var bob_speed := 2.0

var _taken = false
var _base_y = 0.0
var _time = 0.0

@onready var pickup_area: Area3D = $Area3D


func _ready():
	add_to_group("Crystal")
	_base_y = position.y
	# Desync the bob so the four crystals don't move in lockstep.
	_time = randf() * TAU
	pickup_area.body_entered.connect(_on_body_entered)


func _process(delta):
	if _taken:
		return

	_time += delta
	rotate_y(spin_speed * delta)
	position.y = _base_y + sin(_time * bob_speed) * bob_height


func _on_body_entered(body):
	if _taken or not body.is_in_group("Player"):
		return
	_take()


func _take():
	_taken = true
	# Deferred: the Area3D is locked while we're inside its body_entered signal.
	pickup_area.set_deferred("monitoring", false)

	var manager = get_tree().get_first_node_in_group("CrystalManager")
	if manager:
		manager.collect()

	# SHRINK AWAY + RISE, THEN REMOVE THE NODE
	# Never tween to Vector3.ZERO: a zero scale makes the basis non-invertible
	# and Godot throws "Condition det == 0 is true".
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.25)
	tween.tween_property(self, "position:y", position.y + 2.0, 0.25)
	tween.chain().tween_callback(queue_free)
