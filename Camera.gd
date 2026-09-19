extends Node3D

# SCREEN SHAKE ON DAMAGE.
#
# Shakes the pivot's world position (which is rewritten from the player's
# position every frame anyway), so the offset can never accumulate the way a
# rotation tweak would.
const SHAKE_STRENGTH = 1.0
const SHAKE_FADE = 3.0

var mouse_sensitivity = 0.5
var shake_amount = 0.0

@onready var player = get_tree().get_nodes_in_group("Player")[0]

func _ready():
	# Player sits earlier in main.tscn, so the signal exists by now.
	player.health_changed.connect(_on_player_health_changed)

func _process(delta):
	# CAMERA FOLLOWING CHARACTER
	global_position = player.global_position + Vector3(0,4,0)
	apply_shake(delta)

# PLAYER TOOK A HIT
func _on_player_health_changed(_health, _max_health):
	shake_amount = SHAKE_STRENGTH

# TRAPS ASK FOR THE SAME SHAKE WITHOUT DEALING DAMAGE
func shake(strength = SHAKE_STRENGTH):
	shake_amount = max(shake_amount, strength)

func apply_shake(delta):
	if shake_amount <= 0.0:
		return

	shake_amount = max(shake_amount - SHAKE_FADE * delta, 0.0)
	global_position += Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	) * shake_amount

func _input(event):
	
	# HANDLES CAMERA ROTATION ALONG X & Y AXIS
	if event is InputEventMouseMotion:
		var rotx = rotation.x - event.relative.y/1000 * mouse_sensitivity
		rotation.y -= event.relative.x/1000 * mouse_sensitivity
		rotx = clamp(rotx, -1, 1)
		rotation.x = rotx
		
		
	# HANDLES CAMERA ZOOM IN & ZOOM OUT USING MOUSE WHEEL
	if event is InputEventMouseButton:
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var tween = create_tween()
			tween.tween_property($SpringArm3D, "spring_length", max($SpringArm3D.get_length() - 0.5, 4), 0.1)

			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var tween = create_tween()
			tween.tween_property($SpringArm3D, "spring_length", min($SpringArm3D.get_length() + 0.5, 15), 0.1)
			
			

