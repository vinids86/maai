class_name SimpleRecoilState
extends SimpleState

@export var recoil_duration: float = 0.4
@export var recoil_speed: float = 300.0
@export var friction: float = 1000.0

var _timer: float = 0.0
var _current_velocity: Vector2 = Vector2.ZERO

func enter(args: Dictionary = {}):
	owner_node.set_hitbox_enabled(false)
	
	var target_pos = args.get("target_position", Vector2.ZERO)
	var my_pos = owner_node.global_position
	
	var direction = sign(my_pos.x - target_pos.x)
	if direction == 0:
		direction = -owner_node.facing_sign
		
	_current_velocity = Vector2(direction * recoil_speed, -150.0)
	_timer = recoil_duration

func exit():
	owner_node.set_hitbox_enabled(true)

func process_physics(delta: float) -> Vector2:
	_timer -= delta
	if _timer <= 0.0:
		state_machine.on_current_state_finished()
		return Vector2.ZERO

	if not owner_node.is_on_floor():
		_current_velocity.y += 980.0 * delta
	
	_current_velocity.x = move_toward(_current_velocity.x, 0.0, friction * delta)
	
	return _current_velocity
