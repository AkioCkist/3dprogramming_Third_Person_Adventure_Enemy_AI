extends Node3D

# QUEUE FREE THE ENEMY WHEN DEAD
func dead():
	get_parent().queue_free()


# DISABLE ENEMY COLLISION SHAPE WHEN DEAD
func disable_collision():
	get_parent().get_node("CollisionShape3D").disabled = true

# ENEMY ATTACK LANDS ON THE PLAYER - DEAL ONE POINT OF DAMAGE.
# The player owns the health pool and enforces the 2s invulnerability window,
# so this and the body-contact tick can never double-hit on the same frame.
func _on_attack_body_entered(body):

	if body.is_in_group("Player"):
		body.take_damage(1)
