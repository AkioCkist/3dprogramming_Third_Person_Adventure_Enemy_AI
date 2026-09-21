extends Node

# TRACKS CRYSTAL PICKUPS FOR THE LEVEL.
#
# Lives in main.tscn (group "CrystalManager") rather than as an autoload so the
# count resets naturally when Play Again reloads the scene. Crystals report in
# via collect(); the HUD and the Escape gate listen to the signals below.
#
# Also handles game mode logic - Baby Mode allows alerts, Hardcore Mode fails on alert.

signal progress_changed(collected: int, total: int)
signal all_collected()
signal game_failed(reason: String, description: String)

var total := 0
var collected := 0
var game_failed_triggered := false

@onready var game_mode_manager = get_node("/root/GameModeManager")


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
	
	# Only alert enemies in Baby Mode. Hardcore Mode: no alert on collect
	if not game_mode_manager.is_hardcore():
		alert_nearest_enemy()
	
	if is_complete():
		all_collected.emit()


# FIND AND ALERT THE NEAREST ALIVE ENEMY TO CHASE THE PLAYER
func alert_nearest_enemy():
	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		return
	
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var nearest_enemy = null
	var nearest_distance = INF
	
	for enemy in enemies:
		if enemy.dead:
			continue
		var distance = enemy.global_position.distance_to(player.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	
	if nearest_enemy != null:
		nearest_enemy.alert_to_chase(player)
		
		# Register alert in GameModeManager for Hardcore Mode
		game_mode_manager.register_enemy_alert()
		
		# Check if Hardcore Mode fails
		if game_mode_manager.is_hardcore() and not game_failed_triggered:
			game_failed_triggered = true
			_fail_game("Enemy Alerted!", "In Hardcore Mode, you cannot alert any enemy. The game is over.")


func is_complete():
	return total > 0 and collected >= total


# FAIL THE GAME FOR HARDCORE MODE (enemy alert)
func _fail_game(reason: String, description: String):
	game_failed.emit(reason, description)
	
	# Let the GameOverUI handle the display
	var game_over_ui = get_tree().get_first_node_in_group("GameOverUI")
	if game_over_ui:
		game_over_ui.show_game_over_failure(reason, description)
