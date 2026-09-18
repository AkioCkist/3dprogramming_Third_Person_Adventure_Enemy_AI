extends Area3D

# TRIGGER VOLUME THAT SITS OVER THE ESCAPE (area_highlight_carate25) MODEL.
#
# collision_layer = 0 so nothing detects the zone itself, collision_mask = 5
# to match the Player's collision_layer (layers 1 + 3, set in main.tscn).

signal escaped(body)


func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if body.is_in_group("Player") and not body.dead:
		escaped.emit(body)
