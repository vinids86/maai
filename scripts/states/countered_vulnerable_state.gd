class_name CounteredVulnerableState
extends State

var _current_profile: CounterExecutionProfile

enum Phases { VULNERABLE }
var _current_internal_phase: Phases
var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	var result: ContactResult = args.get("result")
	if not result or not result.counter_profile:
		state_machine.on_current_state_finished()
		return

	_current_profile = result.counter_profile
	
	_change_phase(Phases.VULNERABLE)

func process_physics(delta: float, _walk_direction: float, _is_running: bool) -> Vector2:
	if not _current_profile:
		return physics_component.apply_gravity(Vector2.ZERO, delta)

	time_left_in_phase -= delta

	if time_left_in_phase <= 0:
		state_machine.on_current_state_finished()
		return physics_component.apply_gravity(Vector2.ZERO, delta)
	
	var final_velocity = physics_component.apply_gravity(Vector2.ZERO, delta)
	return final_velocity

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func _change_phase(new_phase: Phases):
	_current_internal_phase = new_phase
	
	var sfx_to_play: AudioStream
	var animation_to_play: StringName
	
	match _current_internal_phase:
		Phases.VULNERABLE:
			time_left_in_phase = _current_profile.vulnerable_duration
			animation_to_play = _current_profile.victim_vulnerable_animation

	var phase_data = {
		"state_name": self.name,
		"phase_name": Phases.keys()[_current_internal_phase],
		"profile": _current_profile,
		"sfx_to_play": sfx_to_play,
		"animation_to_play": animation_to_play
	}
	
	state_machine.emit_phase_change(phase_data)

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
