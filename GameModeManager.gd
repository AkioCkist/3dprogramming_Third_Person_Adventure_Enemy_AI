extends Node

# GAME MODE MANAGER (Autoload)
#
# Stores the selected game mode and provides conditions for winning/losing.
# Baby Mode: Collect crystals + reach escape without dying
# Hardcore Mode: Collect crystals + reach escape without alerting ANY enemy

enum Mode { BABY, HARDCORE }

var current_mode: Mode = Mode.BABY
var enemies_alerted: int = 0
var total_crystals_required: int = 5


func set_mode(mode: Mode):
	current_mode = mode
	enemies_alerted = 0


func get_mode_name() -> String:
	match current_mode:
		Mode.BABY:
			return "Baby Mode"
		Mode.HARDCORE:
			return "Hardcore Mode"
	return "Unknown"


func is_hardcore() -> bool:
	return current_mode == Mode.HARDCORE


func register_enemy_alert():
	enemies_alerted += 1


func get_enemies_alerted() -> int:
	return enemies_alerted


func reset():
	enemies_alerted = 0


# Returns true if the player failed based on current mode
func check_failure_condition() -> Dictionary:
	if current_mode == Mode.HARDCORE:
		if enemies_alerted > 0:
			return {
				"failed": true,
				"reason": "Enemy Alerted!",
				"description": "You alerted %d enemy(ies). In Hardcore Mode, you must complete the game without alerting any enemy." % enemies_alerted
			}
	return {"failed": false}


# Returns the win description based on mode
func get_win_description() -> String:
	if current_mode == Mode.BABY:
		return "You collected all %d Heart Crystals and escaped safely!" % total_crystals_required
	else:
		return "Perfect! You collected all %d Heart Crystals without alerting any enemy!" % total_crystals_required


# Returns the objective text for the mission note
func get_objective_text() -> String:
	if current_mode == Mode.BABY:
		return "Collect %d Heart Crystals and reach the Escape Area without losing all health." % total_crystals_required
	else:
		return "Collect %d Heart Crystals and reach the Escape Area WITHOUT alerting any enemy." % total_crystals_required
