class_name SequenceState
extends State

var _attack_executor: AttackExecutor
var _sequence_context: ActionSequence
var _is_initialized: bool = false

func _initialize_references():
	if _is_initialized:
		return
	_attack_executor = owner_node.find_child("AttackExecutor")
	assert(_attack_executor != null, "SequenceState: Nó 'AttackExecutor' não encontrado.")
	_is_initialized = true

func enter(args: Dictionary = {}):
	_initialize_references()
	
	_attack_executor.attack_phase_changed.connect(_on_attack_phase_changed)
	_attack_executor.finished.connect(_on_attack_finished)

	self._sequence_context = args.get("sequence_context")
	if not _sequence_context:
		push_warning("SequenceState: Não recebeu um 'sequence_context'.")
		state_machine.on_current_state_finished()
		return
	
	owner_node.facing_locked = true
	_execute_next_attack_in_sequence()

func exit():
	if _attack_executor:
		_attack_executor.stop()
		if _attack_executor.is_connected("attack_phase_changed", Callable(self, "_on_attack_phase_changed")):
			_attack_executor.attack_phase_changed.disconnect(_on_attack_phase_changed)
		if _attack_executor.is_connected("finished", Callable(self, "_on_attack_finished")):
			_attack_executor.finished.disconnect(_on_attack_finished)
			
	owner_node.facing_locked = false
	_sequence_context = null

func resolve_contact(context: ContactContext) -> ContactResult:
	var result = ContactResult.new()
	result.attacker_node = context.attacker_node
	result.defender_node = context.defender_node
	result.attack_profile = context.attack_profile
	
	var defender_shield_poise = context.defender_poise_comp.get_effective_shield_poise()
	var attacker_offensive_poise = context.attacker_offensive_poise
	
	context.defender_health_comp.take_damage(context.attack_profile.damage)
	
	if attacker_offensive_poise >= defender_shield_poise:
		var reason = {
			"outcome": "POISE_BROKEN",
			"knockback_vector": context.attack_profile.knockback_vector
		}
		state_machine.on_current_state_finished(reason)
		
		result.attacker_outcome = ContactResult.AttackerOutcome.NONE
		result.defender_outcome = ContactResult.DefenderOutcome.POISE_BROKEN
	else:
		result.attacker_outcome = ContactResult.AttackerOutcome.TRADE_LOST
		result.defender_outcome = ContactResult.DefenderOutcome.HIT

	return result

func get_poise_shield_contribution() -> float:
	var profile = _attack_executor.get_current_profile()
	if not profile:
		return 0.0
	return profile.poise_shield_contribution

func get_poise_impact_contribution() -> float:
	var profile = _attack_executor.get_current_profile()
	if not profile:
		return 0.0
	return profile.poise_impact_contribution
	
func _on_attack_phase_changed(phase_data: Dictionary):
	if not _sequence_context:
		return
	state_machine.emit_phase_change(phase_data)

func _on_attack_finished():
	if not _sequence_context:
		return
	_execute_next_attack_in_sequence()

func _execute_next_attack_in_sequence():
	var next_profile = _sequence_context.get_next_profile()
	
	if next_profile:
		if state_machine.stamina_component.try_consume(next_profile.stamina_cost):
			_attack_executor.execute(next_profile)
		else:
			state_machine.on_current_state_finished()
	else:
		state_machine.on_current_state_finished()
