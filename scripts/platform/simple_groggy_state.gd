class_name SimpleGroggyState
extends SimpleState

@export var animation_name: StringName = "hurt"

func enter(_args: Dictionary = {}):
	state_machine.emit_phase_change({
		"state": "SimpleGroggyState",
		"phase": "stunned",
		"animation_to_play": animation_name
	})
	
	owner_node.velocity.x = 0.0

func process_physics(delta: float) -> Vector2:
	var final_velocity = owner_node.velocity
	if not owner_node.is_on_floor():
		final_velocity.y += 980.0 * delta
	
	final_velocity.x = 0.0
	
	return final_velocity
