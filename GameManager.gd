extends Node

# TRACKS CRYSTAL PICKUPS FOR THE LEVEL.
#
# Lives in main.tscn (group "CrystalManager") rather than as an autoload so the
# count resets naturally when Play Again reloads the scene. Crystals report in
# via collect(); the HUD and the Escape gate listen to the signals below.

signal progress_changed(collected: int, total: int)
signal all_collected()

var total := 0
var collected := 0


func _ready():
	add_to_group("CrystalManager")
	# Deferred so every Crystal has run its _ready and joined the group first.
	_count_crystals.call_deferred()


func _count_crystals():
	total = get_tree().get_nodes_in_group("Crystal").size()
	progress_changed.emit(collected, total)


# CALLED BY EACH CRYSTAL WHEN THE PLAYER TOUCHES IT
func collect():
	collected += 1
	progress_changed.emit(collected, total)
	if is_complete():
		all_collected.emit()


func is_complete():
	return total > 0 and collected >= total
