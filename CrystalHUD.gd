extends CanvasLayer

# PERSISTENT CRYSTAL PROGRESS READOUT.
#
# Mirrors GameManager's progress_changed into the bar + label with placeholder icon.

@onready var bar: ProgressBar = $Panel/Margin/Column/Bar
@onready var label: Label = $Panel/Margin/Column/Label


func _ready():
	# Deferred so GameManager has joined the "CrystalManager" group.
	_connect_manager.call_deferred()


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
	label.text = "%d / %d" % [collected, total]
