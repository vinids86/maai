class_name CounteredState
extends State

var current_profile: CounteredProfile
var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")

	if not current_profile:
		push_warning("CounteredState: Não recebeu um CounteredProfile.")
		state_machine.on_current_state_finished()
		return

	time_left_in_phase = current_profile.duration
	
	owner_node.velocity = Vector2.ZERO

	var phase_data := {
		"state_name": self.name,
		"phase_name": "STUN",
		"profile": current_profile,
		"sfx_to_play": current_profile.enter_sfx,
		"animation_to_play": current_profile.animation_name
	}
	state_machine.emit_phase_change(phase_data)

func process_physics(delta: float, _walk_direction: float, _is_running: bool):
	if not current_profile:
		return

	time_left_in_phase -= delta
	if time_left_in_phase <= 0.0:
		state_machine.on_current_state_finished()
		return

func resolve_contact(context: ContactContext) -> ContactResult:
	var result_for_attacker = ContactResult.new()
	result_for_attacker.attacker_node = context.attacker_node
	result_for_attacker.defender_node = context.defender_node
	result_for_attacker.attack_profile = context.attack_profile

	context.defender_health_comp.take_damage(context.attack_profile.damage)
	context.defender_stamina_comp.take_stamina_damage(context.attack_profile.stamina_damage)

	var reason = { "outcome": "POISE_BROKEN", "knockback_vector": context.attack_profile.knockback_vector }
	state_machine.on_current_state_finished(reason)

	result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.POISE_BROKEN
	result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.NONE
	
	return result_for_attacker

func get_poise_shield_contribution() -> float:
	if not current_profile:
		return 0.0
	return current_profile.poise_shield_contribution
