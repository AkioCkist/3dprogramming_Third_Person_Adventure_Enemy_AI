extends CanvasLayer

# FULL SCREEN GAME OVER OVERLAY
#
# Stays visible + interactive while the SceneTree is paused (process_mode =
# PROCESS_MODE_ALWAYS on this node), so the Play Again button still reacts.
#
# Shared by both endings: the Player emits `died` when health reaches zero, and
# the Escape trigger lives in main.tscn and announces itself via the
# "EscapeArea" group.

@onready var overlay = $Overlay
@onready var title: Label = $Overlay/Center/Column/Title
@onready var hint: Label = $Overlay/Center/Column/Hint


func _ready():
	overlay.hide()

	var area = get_tree().get_first_node_in_group("EscapeArea")
	if area:
		area.escaped.connect(_on_escaped)

	# Deferred so the Player has finished its own _ready.
	_connect_player.call_deferred()


func _connect_player():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.died.connect(_on_player_died)


# PLAYER RAN OUT OF HEALTH
func _on_player_died():
	show_game_over("GAME OVER", "You died.", "lose")


# PLAYER TOUCHED THE ESCAPE ZONE WITH EVERY CRYSTAL COLLECTED
func _on_escaped(_body):
	show_game_over("YOU ESCAPED", "All 4 crystals collected.", "win")


func show_game_over(title_text, hint_text, sound_name = ""):
	title.text = title_text
	hint.text = hint_text
	overlay.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# The Player disables viewport input while dying - clear it here or the
	# Play Again button would never receive the click.
	get_tree().get_root().set_disable_input(false)

	# Music out of the way so the stinger is heard. Sound keeps processing while
	# the tree is paused, so the sting still plays after this line.
	Sound.stop_loops()
	Sound.stop_music()
	if sound_name != "":
		Sound.play(sound_name)

	get_tree().paused = true


# RESTART THE WHOLE LEVEL
func _on_play_again_pressed():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# The autoload survived the pause, so the background loop needs a restart.
	Sound.play_music("bg")
	get_tree().reload_current_scene()
