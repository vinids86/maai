class_name StaggerState
extends State

var current_profile: StaggerProfile

var time_left_in_phase: float = 0.0
var _knockback_velocity: Vector2

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")

	if not current_profile:
		state_machine.on_current_state_finished()
		return

	time_left_in_phase = current_profile.duration
	
	var knockback: Vector2 = args.get("knockback_vector", Vector2.ZERO)
	_knockback_velocity = knockback
	if knockback.x != 0:
		_knockback_velocity.x *= -owner_node.facing_sign

	var sfx_to_play = args.get("override_sfx", current_profile.enter_sfx)

	var phase_data := {
		"state_name": self.name,
		"phase_name": "STUN",
		"profile": current_profile,
		"sfx_to_play": sfx_to_play,
		"animation_to_play": current_profile.animation_name
	}
	state_machine.emit_phase_change(phase_data)

func process_physics(delta: float, _walk_direction: float, _is_running: bool):
	if not current_profile:
		return

	time_left_in_phase -= delta
	if time_left_in_phase <= 0.0:
		owner_node.velocity = Vector2.ZERO
		state_machine.on_current_state_finished()
		return
	
	if not owner_node.is_on_floor():
		var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
		_knockback_velocity.y += gravity * delta
	
	_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, 0.1)
	owner_node.velocity = _knockback_velocity
		
	owner_node.move_and_slide()

func resolve_contact(context: ContactContext) -> ContactResult:
	return _resolve_default_contact(context)

func get_poise_shield_contribution() -> float:
	if not current_profile:
		return 0.0
	return current_profile.poise_shield_contribution

func allow_reentry() -> bool:
	return true
