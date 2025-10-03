class_name AttackState
extends State

var _attack_executor: AttackExecutor
var _current_profile: AttackProfile

enum LinkPhases { EXECUTING, LINK }
var _current_phase: LinkPhases
var _time_left_in_link: float = 0.0
var _is_initialized: bool = false

func _initialize_references():
	if _is_initialized:
		return
	_attack_executor = owner_node.find_child("AttackExecutor")
	assert(_attack_executor != null, "AttackState: Nó 'AttackExecutor' não encontrado.")
	_is_initialized = true

func enter(args: Dictionary = {}):
	_initialize_references()
	
	_attack_executor.attack_phase_changed.connect(_on_attack_phase_changed)
	_attack_executor.finished.connect(_on_attack_finished)
	
	self._current_profile = args.get("profile")

	if not _current_profile:
		state_machine.on_current_state_finished()
		return
	
	owner_node.facing_locked = true
	_current_phase = LinkPhases.EXECUTING
	_attack_executor.execute(_current_profile)

func exit():
	if _attack_executor:
		_attack_executor.stop()
		if _attack_executor.is_connected("attack_phase_changed", Callable(self, "_on_attack_phase_changed")):
			_attack_executor.attack_phase_changed.disconnect(_on_attack_phase_changed)
		if _attack_executor.is_connected("finished", Callable(self, "_on_attack_finished")):
			_attack_executor.finished.disconnect(_on_attack_finished)

	owner_node.facing_locked = false
	_current_phase = LinkPhases.EXECUTING
	_current_profile = null

func process_physics(delta: float, _walk_direction: float, _is_running: bool):
	if _current_phase == LinkPhases.LINK:
		_time_left_in_link -= delta
		if _time_left_in_link <= 0.0:
			state_machine.on_current_state_finished()
			return
		
		var move_vel = _current_profile.link_movement_velocity
		owner_node.velocity.x = move_vel.x * owner_node.facing_sign
		owner_node.velocity.y = move_vel.y

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	if _current_phase == LinkPhases.LINK:
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	var executor_phase = _attack_executor.get_current_phase_name()
	var in_startup = executor_phase == "STARTUP"
	var in_link = _current_phase == LinkPhases.LINK
	
	if in_startup or in_link:
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	var executor_phase = _attack_executor.get_current_phase_name()
	var in_recovery = executor_phase == "RECOVERY"
	var in_link = _current_phase == LinkPhases.LINK
	
	if in_recovery or in_link:
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
	
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func resolve_contact(context: ContactContext) -> ContactResult:
	var executor_phase = _attack_executor.get_current_phase_name()

	if executor_phase == "RECOVERY" or _current_phase == LinkPhases.LINK:
		return _resolve_default_contact(context)
	else:
		var result = ContactResult.new()
		result.attacker_node = context.attacker_node
		result.defender_node = context.defender_node
		result.attack_profile = context.attack_profile
		
		var defender_shield_poise = context.defender_poise_comp.get_effective_shield_poise()
		var attacker_offensive_poise = context.attacker_offensive_poise
		
		context.defender_health_comp.take_damage(context.attack_profile.damage)
		
		if attacker_offensive_poise >= defender_shield_poise:
			var reason = { "outcome": "POISE_BROKEN", "knockback_vector": context.attack_profile.knockback_vector }
			state_machine.on_current_state_finished(reason)
			result.attacker_outcome = ContactResult.AttackerOutcome.NONE
			result.defender_outcome = ContactResult.DefenderOutcome.POISE_BROKEN
		else:
			result.attacker_outcome = ContactResult.AttackerOutcome.TRADE_LOST
			result.defender_outcome = ContactResult.DefenderOutcome.HIT

		return result

func get_poise_shield_contribution() -> float:
	if not _current_profile:
		return 0.0

	if _current_phase == LinkPhases.LINK:
		return _current_profile.recovery_poise_shield

	var executor_phase = _attack_executor.get_current_phase_name()
	
	match executor_phase:
		"STARTUP":
			return _current_profile.startup_poise_shield
		"ACTIVE":
			return _current_profile.active_poise_shield
		"RECOVERY":
			return _current_profile.recovery_poise_shield
		_:
			return 0.0

func get_poise_impact_contribution() -> float:
	var profile = _attack_executor.get_current_profile()
	if not profile:
		profile = _current_profile
	if not profile:
		return 0.0
	return profile.poise_impact_contribution

func allow_reentry() -> bool:
	return true

func _on_attack_phase_changed(phase_data: Dictionary):
	state_machine.emit_phase_change(phase_data)

func _on_attack_finished():
	if state_machine.buffer_component.has_buffer():
		state_machine.on_current_state_finished()
		return
	else:
		_current_phase = LinkPhases.LINK
		_time_left_in_link = _current_profile.link_duration
