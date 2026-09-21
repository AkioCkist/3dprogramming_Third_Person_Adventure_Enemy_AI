extends CanvasLayer

# MISSION NOTE UI
#
# Displays current objective in the top-right corner.
# Shows different text based on the selected game mode.

@onready var objective_label: Label = $Panel/MarginContainer/VBox/Objective
@onready var mode_label: Label = $Panel/MarginContainer/VBox/ModeLabel
@onready var icon_placeholder: TextureRect = $Panel/MarginContainer/VBox/Header/IconPlaceholder
@onready var game_mode_manager = get_node("/root/GameModeManager")


func _ready():
	_update_mission_text()
	_create_placeholder_icon()
	
	# Connect to GameManager for crystal progress updates
	var manager = get_tree().get_first_node_in_group("CrystalManager")
	if manager:
		manager.progress_changed.connect(_on_progress_changed)


func _create_placeholder_icon():
	# Create a simple placeholder icon
	var image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 0.8, 0.2, 0.8))
	var texture = ImageTexture.create_from_image(image)
	icon_placeholder.texture = texture


func _update_mission_text():
	if not is_inside_tree():
		return
	
	objective_label.text = game_mode_manager.get_objective_text()
	mode_label.text = "Mode: " + game_mode_manager.get_mode_name()


func _on_progress_changed(collected: int, total: int):
	# Update objective text to show progress
	var base_text = game_mode_manager.get_objective_text()
	if collected < total:
		objective_label.text = "%s\nProgress: %d / %d Crystals collected" % [base_text, collected, total]
	else:
		objective_label.text = "All Crystals collected!\nHead to the Escape Area!"
