class_name WallSlideState
extends State

var current_profile: WallSlideProfile

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")

func exit():
	owner_node.facing_locked = false

func process_physics(delta: float, walk_direction: float, _is_running: bool) -> Vector2:
	if not current_profile:
		state_machine.on_current_state_finished()
		return Vector2.ZERO

	if not wall_detector.is_on_wall(owner_node.facing_sign, walk_direction) or owner_node.is_on_floor():
		state_machine.on_current_state_finished()
		return owner_node.velocity

	var new_velocity = owner_node.velocity
	new_velocity.y = current_profile.slide_speed
	new_velocity.x = 0
	
	return new_velocity

func handle_jump_input(_profile: JumpProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED, {"is_wall_jump": true})

func resolve_contact(context: ContactContext) -> ContactResult:
	context.defender_health_comp.take_damage(context.attack_profile.damage)
	
	var reason = { "outcome": "POISE_BROKEN", "knockback_vector": context.attack_profile.knockback_vector }
	state_machine.on_current_state_finished(reason)
	
	var result_for_attacker = ContactResult.new()
	result_for_attacker.attacker_node = context.attacker_node
	result_for_attacker.defender_node = context.defender_node
	result_for_attacker.attack_profile = context.attack_profile
	result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.POISE_BROKEN
	result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.NONE
	return result_for_attacker

func get_poise_shield_contribution() -> float:
	return 0.0
