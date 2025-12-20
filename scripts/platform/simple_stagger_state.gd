class_name SimpleStaggerState
extends SimpleState

@export var stagger_duration: float = 0.6
@export var audio: AudioStream

@export var ground_friction: float = 2500.0 
@export var air_friction: float = 400.0 

@export_range(0.0, 1.0) var knockback_multiplier: float = 0.5 

var _timer: float = 0.0
var _current_velocity: Vector2 = Vector2.ZERO
var _is_first_frame: bool = false

func enter(args: Dictionary = {}):
	owner_node.set_hitbox_enabled(false)
	
	var raw_knockback = args.get("knockback_vector", Vector2.ZERO)
	
	_current_velocity = raw_knockback * knockback_multiplier
	
	_timer = stagger_duration
	_is_first_frame = true
	
	state_machine.emit_phase_change({
		"state": "SimpleStaggerState",
		"phase": "hurt",
		"sfx_to_play": audio,
		"animation_to_play": "hit"
	})

func process_physics(delta: float) -> Vector2:
	_timer -= delta
	if _timer <= 0.0:
		state_machine.on_current_state_finished()
		return Vector2.ZERO

	if not _is_first_frame:
		_current_velocity = owner_node.velocity
	else:
		_is_first_frame = false

	if not owner_node.is_on_floor():
		_current_velocity.y += 980.0 * delta
		_current_velocity.x = move_toward(_current_velocity.x, 0.0, air_friction * delta)
	else:
		_current_velocity.x = move_toward(_current_velocity.x, 0.0, ground_friction * delta)
	
	return _current_velocity

func exit():
	owner_node.set_hitbox_enabled(true)
	owner_node.velocity = Vector2.ZERO
