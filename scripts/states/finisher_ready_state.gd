class_name FinisherReadyState
extends State

var current_profile: FinisherProfile

var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")

	if not current_profile:
		state_machine.on_current_state_finished()
		return

	time_left_in_phase = current_profile.ready_duration
	_emit_phase_signal()

func process_physics(delta: float, _walk_direction: float, _is_running: bool):
	if not current_profile:
		return

	time_left_in_phase -= delta
	if time_left_in_phase <= 0:
		state_machine.on_current_state_finished()

func resolve_contact(context: ContactContext) -> ContactResult:
	return _handle_default_hit(context)

func _handle_default_hit(context: ContactContext) -> ContactResult:
	var attack_profile = context.attack_profile
	var was_poise_broken = false
	if context.defender_poise_comp and attack_profile.poise_damage >= context.defender_poise_comp.get_effective_poise():
		was_poise_broken = true
	
	context.defender_health_comp.take_damage(attack_profile.damage)
	
	var outcome = "HIT"
	if was_poise_broken:
		outcome = "POISE_BROKEN"
	
	state_machine.on_current_state_finished({"outcome": outcome})
	
	var result = ContactResult.new()
	result.attacker_outcome = ContactResult.AttackerOutcome.NONE
	result.attacker_node = context.attacker_node
	result.defender_node = context.defender_node
	result.attack_profile = context.attack_profile
	return result

func allow_attack() -> bool:
	return true

func _emit_phase_signal():
	var phase_data = {
		"state_name": self.name,
		"phase_name": "FINISHER_READY",
		"profile": current_profile,
		"animation_to_play": current_profile.animation_name,
		"sfx_to_play": current_profile.sfx
	}
	state_machine.emit_phase_change(phase_data)
