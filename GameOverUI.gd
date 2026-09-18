extends CanvasLayer

# FULL SCREEN GAME OVER OVERLAY
#
# Stays visible + interactive while the SceneTree is paused (process_mode =
# PROCESS_MODE_ALWAYS on this node), so the Play Again button still reacts.

@onready var overlay = $Overlay


func _ready():
	overlay.hide()
	# The Escape trigger lives in main.tscn and announces itself via this group.
	var area = get_tree().get_first_node_in_group("EscapeArea")
	if area:
		area.escaped.connect(_on_escaped)


# PLAYER TOUCHED THE ESCAPE ZONE
func _on_escaped(_body):
	overlay.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true


# RESTART THE WHOLE LEVEL
func _on_play_again_pressed():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().reload_current_scene()
