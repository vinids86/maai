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

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	var finisher_attack_profile = owner_node.get_finisher_attack_profile()

	if finisher_attack_profile:
		state_machine.transition_to("AttackState", {"profile": finisher_attack_profile})
		
		return InputHandlerResult.new(InputHandlerResult.Status.CONSUMED)

	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func resolve_contact(context: ContactContext) -> ContactResult:
	return _resolve_default_contact(context)

func get_poise_shield_contribution() -> float:
	if not current_profile:
		return 0.0
	return current_profile.poise_shield_contribution

func get_poise_impact_contribution() -> float:
	return 0.0

func _emit_phase_signal():
	var phase_data = {
		"state_name": self.name,
		"phase_name": "FINISHER_READY",
		"profile": current_profile,
		"animation_to_play": current_profile.animation_name,
		"sfx_to_play": current_profile.sfx
	}
	state_machine.emit_phase_change(phase_data)
