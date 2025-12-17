class_name SimpleDeathState
extends SimpleState

func enter(_args: Dictionary = {}):
	var profile: DeathProfile = owner_node.get_death_profile()
	
	state_machine.emit_phase_change({
		"state": "SimpleDeathState",
		"phase": "die",
		"animation_to_play": profile.animation_name,
		"sfx_to_play": profile.sfx
	})
	
	# Desabilita colisão física principal
	var collider = owner_node.get_node_or_null("CollisionShape2D")
	if collider:
		collider.set_deferred("disabled", true)
	
	# Desabilita Hurtbox (não recebe mais dano)
	var hurtbox_shape = owner_node.get_node_or_null("Hurtbox/CollisionShape2D")
	if hurtbox_shape:
		hurtbox_shape.set_deferred("disabled", true)
		
	# Desabilita Hitbox (não dá mais dano se o player encostar no corpo caindo)
	owner_node.set_hitbox_enabled(false)

func process_physics(_delta: float) -> Vector2:
	# Para o movimento completamente
	return Vector2.ZERO
