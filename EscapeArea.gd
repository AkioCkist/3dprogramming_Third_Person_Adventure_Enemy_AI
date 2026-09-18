extends Area3D

# TRIGGER VOLUME THAT SITS OVER THE ESCAPE (area_highlight_carate25) MODEL.
#
# collision_layer = 0 so nothing detects the zone itself, collision_mask = 5
# to match the Player's collision_layer (layers 1 + 3, set in main.tscn).
#
# The zone is inert until every crystal is collected: the escape model stays
# hidden and touching the volume does nothing. Once GameManager reports all
# crystals found, the model pops in and a touch fires the win.

signal escaped(body)

const ESCAPE_VISUAL_GROUP = "EscapeVisual"


func _ready():
	var visual = get_tree().get_first_node_in_group(ESCAPE_VISUAL_GROUP)
	if visual:
		visual.visible = false
	body_entered.connect(_on_body_entered)
	# Deferred so GameManager has joined the "CrystalManager" group.
	_connect_manager.call_deferred()


func _connect_manager():
	var manager = get_tree().get_first_node_in_group("CrystalManager")
	if manager:
		manager.all_collected.connect(_on_all_collected)
		# Handle the case where the level is already complete (e.g. re-entering).
		if manager.is_complete():
			_on_all_collected()


func _on_all_collected():
	var visual = get_tree().get_first_node_in_group(ESCAPE_VISUAL_GROUP)
	if visual:
		visual.visible = true


func _on_body_entered(body):
	if not body.is_in_group("Player") or body.dead:
		return

	var manager = get_tree().get_first_node_in_group("CrystalManager")
	if manager == null or not manager.is_complete():
		return

	escaped.emit(body)
