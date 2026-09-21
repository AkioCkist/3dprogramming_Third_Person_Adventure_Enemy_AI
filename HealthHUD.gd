extends CanvasLayer

# PLAYER HEALTH BAR.
#
# Mirrors the Player's health_changed signal. Shows hearts with placeholder icons.

const HEALTH_LOW = Color(0.9, 0.25, 0.25)
const HEALTH_HIGH = Color(0.2, 0.86, 0.45)

@onready var bar: ProgressBar = $Panel/Margin/Column/Bar
@onready var label: Label = $Panel/Margin/Column/Label

var _player


func _ready():
	# Deferred so the Player has finished its own _ready.
	_connect_player.call_deferred()


func _connect_player():
	_player = get_tree().get_first_node_in_group("Player")
	if _player == null:
		return
	_player.health_changed.connect(_on_health_changed)
	# Sync immediately - the player does not emit on spawn.
	_on_health_changed(_player.health, _player.max_health)


func _on_health_changed(health: int, max_health: int):
	bar.max_value = max(max_health, 1)
	bar.value = health
	label.text = "%d / %d" % [health, max_health]

	# Fade the fill from green to red as health drops.
	if bar.has_theme_stylebox_override("fill"):
		var fill = bar.get_theme_stylebox("fill")
		if fill is StyleBoxFlat:
			fill.bg_color = HEALTH_LOW.lerp(
				HEALTH_HIGH, float(health) / float(max(max_health, 1))
			)
