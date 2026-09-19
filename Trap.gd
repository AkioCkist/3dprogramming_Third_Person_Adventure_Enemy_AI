extends Area3D

# BEAR TRAP - ONE SHOT.
#
# Tripping it plays the snap animation and halves the speed of whoever stepped
# in - player or enemy. The player trip also fires the same hit feedback the
# enemies do: camera shake + red overlay. A tripped trap never fires again.

@export var slow_factor = 0.5
@export var slow_duration = 3.0
@export var shake_strength = 1.0
# Screen feedback on an enemy trip too, not just the player's.
@export var feedback_on_enemy = false
# Empty = play whatever clip the imported model ships with.
@export var animation_name = ""

var triggered = false

@onready var animation : AnimationPlayer = $Sketchfab_Scene/AnimationPlayer


func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if triggered:
		return

	var is_player = body.is_in_group("Player")
	if not is_player and not body.is_in_group("Enemy"):
		return

	# A DEAD ENEMY IS ALREADY DISABLED - DON'T WASTE THE TRAP ON IT
	if body.get("dead") == true:
		return

	triggered = true
	# NO SECOND TRIP - DEFERRED BECAUSE WE ARE INSIDE THE PHYSICS CALLBACK
	set_deferred("monitoring", false)

	play_snap()
	body.apply_slow(slow_factor, slow_duration)

	if is_player or feedback_on_enemy:
		hit_feedback()

	if is_player:
		Sound.play("trap")


func play_snap():
	if animation == null:
		return

	var clip = animation_name
	if clip == "":
		var clips = animation.get_animation_list()
		if clips.is_empty():
			return
		clip = clips[0]

	animation.play(clip)


# SAME FEEDBACK THE PLAYER GETS WHEN AN ENEMY HITS THEM
func hit_feedback():
	var camera = get_tree().get_first_node_in_group("Camera")
	if camera and camera.has_method("shake"):
		camera.shake(shake_strength)

	var overlay = get_tree().get_first_node_in_group("DamageOverlay")
	if overlay and overlay.has_method("flash"):
		overlay.flash()
