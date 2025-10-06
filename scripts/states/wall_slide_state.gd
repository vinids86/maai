class_name WallSlideState
extends State

var current_profile: WallSlideProfile

func enter(args: Dictionary = {}):
	current_profile = args.get("profile")
	if not current_profile:
		state_machine.on_current_state_finished()
		return

	owner_node.facing_sign *= -1
	owner_node.facing_locked = true
	
	_emit_phase_signal()

func exit():
	owner_node.facing_locked = false

func process_physics(delta: float, _walk_direction: float, _is_running: bool) -> Vector2:
	if owner_node.is_on_floor():
		state_machine.on_current_state_finished()
		return Vector2.ZERO

	var wall_direction = -owner_node.facing_sign
	if not wall_detector.is_colliding(wall_direction):
		state_machine.on_current_state_finished()
		return owner_node.velocity

	var new_velocity = Vector2.ZERO
	if current_profile:
		new_velocity.y = current_profile.slide_speed

	return new_velocity

func handle_jump_input(_profile: JumpProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED, {"is_wall_jump": true})

func handle_dash_input(_profile: DashProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

func resolve_contact(context: ContactContext) -> ContactResult:
	context.defender_health_comp.take_damage(context.attack_profile.damage)
	
	var reason = {"outcome": "POISE_BROKEN", "knockback_vector": context.attack_profile.knockback_vector}
	state_machine.on_current_state_finished(reason)

	var result = ContactResult.new()
	result.attacker_node = context.attacker_node
	result.defender_node = context.defender_node
	result.attack_profile = context.attack_profile
	result.defender_outcome = ContactResult.DefenderOutcome.POISE_BROKEN
	result.attacker_outcome = ContactResult.AttackerOutcome.NONE
	return result

func _emit_phase_signal():
	var phase_data = {
		"state_name": self.name,
		"phase_name": "SLIDING",
		"profile": current_profile,
	}
	if current_profile and current_profile.animation_name:
		phase_data["animation_to_play"] = current_profile.animation_name
	if current_profile and current_profile.sfx:
		phase_data["sfx_to_play"] = current_profile.sfx
	
	state_machine.emit_phase_change(phase_data)
