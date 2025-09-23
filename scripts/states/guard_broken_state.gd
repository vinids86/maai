class_name GuardBrokenState
extends State

var current_profile: GuardBrokenProfile

var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")

	if not current_profile:
		push_warning("GuardBrokenState: Não recebeu um GuardBrokenProfile. A abortar.")
		state_machine.on_current_state_finished()
		return

	time_left_in_phase = current_profile.duration
	owner_node.velocity = Vector2.ZERO
	_emit_phase_signal()


func process_physics(delta: float, _walk_direction: float, _is_running: bool):
	if not current_profile:
		return

	time_left_in_phase -= delta
	if time_left_in_phase <= 0:
		state_machine.on_current_state_finished()

func resolve_contact(context: ContactContext) -> ContactResult:
	var finisher_profile = owner_node.get_finisher_profile()
	if finisher_profile:
		context.defender_health_comp.take_damage(finisher_profile.attack_profile.damage)
	
	context.defender_stamina_comp.restore_to_full()
	
	state_machine.on_current_state_finished({"outcome": "FINISHER_HIT"})
	
	var result_for_attacker = ContactResult.new()
	result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.FINISHER_SUCCESS
	result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.FINISHER_HIT
	result_for_attacker.attacker_node = context.attacker_node
	result_for_attacker.defender_node = context.defender_node
	result_for_attacker.attack_profile = context.attack_profile
	return result_for_attacker

func get_poise_shield_contribution() -> float:
	if not current_profile:
		return 0.0
	return current_profile.poise_shield_contribution

func _emit_phase_signal():
	var phase_data = {
		"state_name": self.name,
		"phase_name": "GUARD_BROKEN",
		"profile": current_profile,
		"animation_to_play": current_profile.animation_name,
		"sfx_to_play": current_profile.enter_sfx
	}
	state_machine.emit_phase_change(phase_data)
