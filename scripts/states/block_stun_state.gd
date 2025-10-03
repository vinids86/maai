class_name BlockStunState
extends State

var current_profile: BlockStunProfile

var time_left_in_phase: float = 0.0
var _recoil_velocity: Vector2

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")

	if not current_profile:
		state_machine.on_current_state_finished()
		return
	
	time_left_in_phase = current_profile.duration
	
	var recoil: Vector2 = args.get("knockback_vector", Vector2.ZERO)
	_recoil_velocity = recoil
	if recoil.x != 0:
		_recoil_velocity.x *= -owner_node.facing_sign
	
	_emit_phase_signal()

func process_physics(delta: float, _walk_direction: float, _is_running: bool):
	if not current_profile:
		return

	time_left_in_phase -= delta
	if time_left_in_phase <= 0:
		owner_node.velocity = Vector2.ZERO
		state_machine.on_current_state_finished()
		return
		
	if not owner_node.is_on_floor():
		var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
		_recoil_velocity.y += gravity * delta
	
	_recoil_velocity = _recoil_velocity.lerp(Vector2.ZERO, 0.15)
	owner_node.velocity = _recoil_velocity
	
	owner_node.move_and_slide()

func resolve_contact(context: ContactContext) -> ContactResult:
	return _resolve_default_contact(context)

func get_poise_shield_contribution() -> float:
	if not current_profile:
		return 0.0
	return current_profile.poise_shield_contribution

func allow_reentry() -> bool:
	return true

func _emit_phase_signal():
	var phase_data = {
		"state_name": self.name,
		"phase_name": "BLOCK_STUN",
		"profile": current_profile,
		"animation_to_play": current_profile.animation_name,
		"sfx_to_play": current_profile.sfx
	}
	state_machine.emit_phase_change(phase_data)
