class_name SimpleParriedState
extends SimpleState

@export var friction: float = 1200.0
@export var knockback_force: float = 600.0
@export var duration_failsafe: float = 0.5

var _timer: float = 0.0
var _current_velocity: Vector2 = Vector2.ZERO

func enter(args: Dictionary = {}):
	state_machine.emit_phase_change({"new_phase": "PARRIED"})
	
	_timer = duration_failsafe
	
	var direction = args.get("direction", Vector2.ZERO)
	
	if direction != Vector2.ZERO:
		_current_velocity = direction * knockback_force
	else:
		var facing = -1.0
		facing = -owner_node.get_facing_direction()
		_current_velocity = Vector2(facing * knockback_force, 0)
	
	_current_velocity.y = -150.0 

func process_physics(delta: float) -> Vector2:
	_timer -= delta
	
	if owner_node.is_on_floor() and _current_velocity.y > 0:
		_current_velocity.y = 10.0
	else:
		_current_velocity.y += 980 * delta
	
	_current_velocity.x = move_toward(_current_velocity.x, 0, friction * delta)
	
	if abs(_current_velocity.x) < 10.0 or _timer <= 0:
		state_machine.on_current_state_finished({"outcome": "PARRY_RECOVERED"})
		return Vector2.ZERO
			
	return _current_velocity
