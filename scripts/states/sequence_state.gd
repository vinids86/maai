class_name SequenceState
extends State

enum LinkPhases { ACTIVE, LINK, FINISHED }
var _current_phase: LinkPhases = LinkPhases.FINISHED
var _time_left_in_link: float = 0.0

var _attack_executor: AttackExecutor
var _is_initialized: bool = false

var _skill_sequence: ActionSequence
var _current_profile: AttackProfile

func enter(args: Dictionary = {}):
	if not _is_initialized:
		_attack_executor = owner_node.find_child("AttackExecutor")
		assert(_attack_executor != null, "SequenceState: Nó 'AttackExecutor' não encontrado como irmão.")
		_is_initialized = true
		
	_attack_executor.finished.connect(_on_attack_finished)
	_attack_executor.attack_phase_changed.connect(_on_phase_changed)

	_skill_sequence = args.get("sequence_context")
	if not _skill_sequence:
		state_machine.on_current_state_finished()
		return
	
	_current_phase = LinkPhases.ACTIVE
	_execute_next_attack()

func exit():
	if _attack_executor:
		if _attack_executor.is_connected("finished", Callable(self, "_on_attack_finished")):
			_attack_executor.finished.disconnect(_on_attack_finished)
		if _attack_executor.is_connected("attack_phase_changed", Callable(self, "_on_phase_changed")):
			_attack_executor.attack_phase_changed.disconnect(_on_phase_changed)
		_attack_executor.stop()
		
	_current_profile = null
	_current_phase = LinkPhases.FINISHED

func process_physics(delta: float, _walk_direction: float, _is_running: bool):
	if _current_phase == LinkPhases.LINK:
		_time_left_in_link -= delta
		if _time_left_in_link <= 0.0:
			_current_phase = LinkPhases.FINISHED
			state_machine.on_current_state_finished()

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	if _current_phase == LinkPhases.LINK:
		return InputHandlerResult.ACCEPTED
	return InputHandlerResult.REJECTED

func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	if _current_phase == LinkPhases.LINK:
		return InputHandlerResult.ACCEPTED
	return InputHandlerResult.REJECTED

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	if _current_phase == LinkPhases.LINK:
		return InputHandlerResult.ACCEPTED
	return InputHandlerResult.REJECTED

func _on_attack_finished():
	_execute_next_attack()

func _execute_next_attack():
	if _current_phase != LinkPhases.ACTIVE:
		return

	var next_profile = _skill_sequence.get_next_profile()

	if next_profile:
		if state_machine.stamina_component.try_consume(next_profile.stamina_cost):
			_current_profile = next_profile
			_attack_executor.execute(_current_profile)
		else:
			_current_phase = LinkPhases.FINISHED
			state_machine.on_current_state_finished()
	else:
		if state_machine.buffer_component.has_buffer():
			_current_phase = LinkPhases.FINISHED
			state_machine.on_current_state_finished()
			return
		
		if not _current_profile:
			_current_phase = LinkPhases.FINISHED
			state_machine.on_current_state_finished()
			return
		
		_current_phase = LinkPhases.LINK
		_time_left_in_link = _current_profile.link_duration
		
func resolve_contact(context: ContactContext) -> ContactResult:
	var result = ContactResult.new()
	result.attacker_node = context.attacker_node
	result.defender_node = context.defender_node
	result.attack_profile = context.attack_profile
	
	var my_shield_poise = context.defender_poise_comp.get_effective_shield_poise()
	var attacker_sword_poise = context.attacker_offensive_poise
	
	context.defender_health_comp.take_damage(context.attack_profile.damage)
	
	if attacker_sword_poise >= my_shield_poise:
		var reason = { "outcome": "POISE_BROKEN", "knockback_vector": context.attack_profile.knockback_vector }
		state_machine.on_current_state_finished(reason)
		
		result.attacker_outcome = ContactResult.AttackerOutcome.NONE
		result.defender_outcome = ContactResult.DefenderOutcome.POISE_BROKEN
	else:
		result.attacker_outcome = ContactResult.AttackerOutcome.TRADE_LOST
		result.defender_outcome = ContactResult.DefenderOutcome.HIT

	return result

func get_poise_shield_contribution() -> float:
	if not _current_profile: return 0.0
	return _current_profile.poise_shield_contribution

func get_poise_impact_contribution() -> float:
	if not _current_profile: return 0.0
	return _current_profile.poise_impact_contribution

func get_attack_profile() -> AttackProfile:
	return _current_profile

func allow_reentry() -> bool:
	return true

func _on_phase_changed(phase_data: Dictionary):
	state_machine.emit_phase_change(phase_data)
