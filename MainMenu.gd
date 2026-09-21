extends Control

# MAIN MENU - MODE SELECTION SCREEN
#
# Allows the player to choose between Baby Mode and Hardcore Mode.
# Stores the selected mode in GameMode autoload and loads main.tscn.

enum GameMode { BABY, HARDCORE }

@onready var game_mode_manager = get_node("/root/GameModeManager")


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Set placeholder colors for mode icons
	var baby_icon = $VBoxContainer/ModesContainer/BabyMode/BabyIcon
	var hardcore_icon = $VBoxContainer/ModesContainer/HardcoreMode/HardcoreIcon
	
	# Create placeholder backgrounds
	_create_placeholder_icon(baby_icon, Color(0.3, 0.7, 0.4, 0.5), "BABY")
	_create_placeholder_icon(hardcore_icon, Color(0.8, 0.2, 0.2, 0.5), "HARDCORE")


func _create_placeholder_icon(texture_rect: TextureRect, bg_color: Color, text: String):
	# Create a simple placeholder image
	var image = Image.create(120, 120, false, Image.FORMAT_RGBA8)
	image.fill(bg_color)
	
	var image_texture = ImageTexture.create_from_image(image)
	texture_rect.texture = image_texture


func _on_baby_button_pressed():
	_start_game(GameMode.BABY)


func _on_hardcore_button_pressed():
	_start_game(GameMode.HARDCORE)


func _start_game(mode: GameMode):
	# Store the selected mode globally
	# Set the mode before loading the scene
	game_mode_manager.set_mode(mode)
	
	# Load the game scene
	get_tree().change_scene_to_file("res://main.tscn")


func _create_game_mode_autoload():
	# This will be created as a separate file
	pass
