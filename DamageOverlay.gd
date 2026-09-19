extends CanvasLayer

# RED FULL-SCREEN FLASH ON DAMAGE.
#
# Sits on layer 0 so the crystal / health HUD (layer 1) stays readable on top.
# The colour rect is mouse_filter = IGNORE and never blocks input.

const PEAK_ALPHA = 0.35
const FADE_TIME = 0.7

@onready var rect: ColorRect = $Rect

var _player


func _ready():
	rect.color.a = 0.0
	# Deferred so the Player has finished its own _ready.
	_connect_player.call_deferred()


func _connect_player():
	_player = get_tree().get_first_node_in_group("Player")
	if _player:
		_player.health_changed.connect(_on_health_changed)


# The Player only emits this on an actual hit, so no need to filter spawn state.
func _on_health_changed(_health, _max_health):
	rect.color.a = PEAK_ALPHA


# TRAPS AND OTHER NON-DAMAGE HITS FLASH THE SCREEN THE SAME WAY
func flash():
	rect.color.a = PEAK_ALPHA


func _process(delta):
	if rect.color.a <= 0.0:
		return

	rect.color.a = max(rect.color.a - (PEAK_ALPHA / FADE_TIME) * delta, 0.0)
