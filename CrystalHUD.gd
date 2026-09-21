extends CanvasLayer

# PERSISTENT CRYSTAL PROGRESS READOUT.
#
# Mirrors GameManager's progress_changed into the bar + label with placeholder icon.

@onready var bar: ProgressBar = $Panel/Margin/Column/Bar
@onready var label: Label = $Panel/Margin/Column/Label


func _ready():
	_setup_icon()
	# Deferred so GameManager has joined the "CrystalManager" group.
	_connect_manager.call_deferred()


func _setup_icon():
	var hbox = HBoxContainer.new()
	var column = label.get_parent()
	var label_index = label.get_index()
	
	column.add_child(hbox)
	column.move_child(hbox, label_index)
	
	var icon = TextureRect.new()
	icon.texture = load("res://icon/heart_crystal.png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(40, 40)
	
	hbox.add_child(icon)
	
	column.remove_child(label)
	hbox.add_child(label)


func _connect_manager():
	var manager = get_tree().get_first_node_in_group("CrystalManager")
	if manager == null:
		return
	manager.progress_changed.connect(_on_progress_changed)
	# Sync immediately in case GameManager already emitted.
	_on_progress_changed(manager.collected, manager.total)


func _on_progress_changed(collected: int, total: int):
	bar.max_value = max(total, 1)
	bar.value = collected
	label.text = "CRYSTAL  %d / %d" % [collected, total]
