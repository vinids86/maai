class_name AirAttackState
extends State

var _attack_executor: AttackExecutor
var _air_combo_component: AirComboComponent
var _air_mobility_component: AirMobilityComponent
var _is_initialized: bool = false

# Controle local
var _is_gravity_suspended: bool = false
var _current_attack_has_hit: bool = false
var _current_profile: AttackProfile = null

func _initialize_references():
	if _is_initialized: return
	_attack_executor = owner_node.find_child("AttackExecutor")
	_air_combo_component = owner_node.find_child("AirComboComponent")
	_air_mobility_component = owner_node.find_child("AirMobilityComponent")
	_is_initialized = true

func enter(args: Dictionary = {}) -> void:
	_initialize_references()
	
	_current_profile = args.get("profile")
	_reset_attack_state()
	
	if not _attack_executor.attack_phase_changed.is_connected(_on_phase_changed):
		_attack_executor.attack_phase_changed.connect(_on_phase_changed)
	if not _attack_executor.finished.is_connected(_on_attack_finished):
		_attack_executor.finished.connect(_on_attack_finished)
		
	if _current_profile:
		_execute_attack(_current_profile)

func exit() -> void:
	if _attack_executor.attack_phase_changed.is_connected(_on_phase_changed):
		_attack_executor.attack_phase_changed.disconnect(_on_phase_changed)
	if _attack_executor.finished.is_connected(_on_attack_finished):
		_attack_executor.finished.disconnect(_on_attack_finished)
	
	_attack_executor.stop()
	_current_profile = null
	_is_gravity_suspended = false
	_current_attack_has_hit = false

func process_physics(delta: float, _walk_direction: float, _is_running: bool) -> Vector2:
	var new_velocity = owner_node.velocity
	
	if not _is_gravity_suspended:
		new_velocity = physics_component.apply_gravity(new_velocity, delta)
	else:
		new_velocity.y = 0.0
	
	if owner_node.is_on_floor():
		# A StateMachine agora cuidará do reset_air_actions() ao processar isso
		state_machine.on_current_state_finished()
		return Vector2.ZERO
		
	return new_velocity

func handle_attack_input(profile: AttackProfile) -> InputHandlerResult:
	var phase = _attack_executor.get_current_phase_name()
	# Lógica de Combo INTERNO:
	# Se estamos em recovery, tentamos pagar o custo e executar aqui mesmo.
	# Retornamos CONSUMED para que a StateMachine NÃO tente transitar.
	if phase == "RECOVERY":
		if state_machine.action_cost_validator.try_pay_costs(profile):
			_execute_attack(profile)
			return InputHandlerResult.new(InputHandlerResult.Status.CONSUMED)
	
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_jump_input(profile: JumpProfile) -> InputHandlerResult:
	var phase = _attack_executor.get_current_phase_name()
	# Cancelamento de Pulo: Retornamos ACCEPTED.
	# A StateMachine vai capturar isso e transitar para AirborneState.
	if phase == "RECOVERY":
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dash_input(_profile: DashProfile) -> InputHandlerResult:
	var phase = _attack_executor.get_current_phase_name()
	if phase == "RECOVERY":
		# Se consumiu o dash, retornamos ACCEPTED para que a StateMachine
		# possa transitar para o estado de Dash se necessário, ou processar o evento.
		if _air_mobility_component.try_consume_air_dash():
			return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func _execute_attack(profile: AttackProfile) -> void:
	_reset_attack_state()
	_current_profile = profile
	_attack_executor.execute(profile)
	_air_combo_component.advance_combo()
	print("profile: ", profile.active_sfx)

func _reset_attack_state() -> void:
	_current_attack_has_hit = false
	_is_gravity_suspended = false

func _on_attack_finished() -> void:
	# Buffer Interno
	var buffered_data = state_machine.query_buffered_action()
	if buffered_data and buffered_data.action == BufferComponent.BufferedAction.ATTACK:
		var next_profile = _air_combo_component.get_next_attack_profile()
		if next_profile and state_machine.action_cost_validator.try_pay_costs(next_profile):
			_execute_attack(next_profile)
			return

	state_machine.on_current_state_finished()

func handle_attack_outcome(outcome: ContactResult) -> void:
	var result = outcome.attacker_outcome
	if result == ContactResult.AttackerOutcome.HIT_SUCCESS_SIMPLE_ENEMY:
		_is_gravity_suspended = true
		_current_attack_has_hit = true
		owner_node.velocity.y = 0.0

func _on_phase_changed(phase_data: Dictionary):
	state_machine.emit_phase_change(phase_data)

func get_poise_shield_contribution() -> float:
	var executor_phase = _attack_executor.get_current_phase_name()
	if _current_profile:
		match executor_phase:
			"STARTUP": return _current_profile.startup_poise_shield
			"ACTIVE": return _current_profile.active_poise_shield
			"RECOVERY": return _current_profile.recovery_poise_shield
	return 0.0
