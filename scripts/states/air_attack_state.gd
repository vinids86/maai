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
	
	# Garante estado limpo ao iniciar o combo. 
	# Isso deve resetar o índice do AirComboComponent para 0.
	_attack_executor.stop()
	
	if _current_profile:
		_execute_attack(_current_profile)

func exit() -> void:
	_disconnect_signals()
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
		state_machine.on_current_state_finished()
		return Vector2.ZERO
		
	return new_velocity

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	# Buffer: Rejeita o input para que a StateMachine o armazene.
	# O próximo ataque será processado em _on_attack_finished.
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_jump_input(_profile: JumpProfile) -> InputHandlerResult:
	var phase = _attack_executor.get_current_phase_name()
	if phase == "RECOVERY":
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dash_input(_profile: DashProfile) -> InputHandlerResult:
	var phase = _attack_executor.get_current_phase_name()
	if phase == "RECOVERY":
		var targeting = owner_node.find_child("SmartTargetingComponent")
		if targeting and targeting.current_target:
			return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

		if _air_mobility_component.try_consume_air_dash():
			return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
			
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func _execute_attack(profile: AttackProfile) -> void:
	# 1. Limpeza de conexões antigas
	_disconnect_signals()
	
	_reset_attack_state()
	_current_profile = profile
	
	# 2. Conectar sinais
	_connect_signals()
	
	# 3. Executar o ataque
	_attack_executor.execute(profile)
	
	# 4. Avançar o combo com segurança (Deferred)
	# Usamos call_deferred para garantir que o AttackExecutor já tenha processado 
	# o início da animação e esteja com status 'playing', caso o componente verifique isso.
	call_deferred("_advance_combo_safe")

func _advance_combo_safe() -> void:
	# Verificação de segurança: só avança se ainda estivermos no estado e atacando
	if _current_profile and state_machine.current_state == self:
		_air_combo_component.advance_combo()

func _reset_attack_state() -> void:
	_current_attack_has_hit = false
	_is_gravity_suspended = false

func _connect_signals() -> void:
	if not _attack_executor.attack_phase_changed.is_connected(_on_phase_changed):
		_attack_executor.attack_phase_changed.connect(_on_phase_changed)
	if not _attack_executor.finished.is_connected(_on_attack_finished):
		_attack_executor.finished.connect(_on_attack_finished)

func _disconnect_signals() -> void:
	if _attack_executor.attack_phase_changed.is_connected(_on_phase_changed):
		_attack_executor.attack_phase_changed.disconnect(_on_phase_changed)
	if _attack_executor.finished.is_connected(_on_attack_finished):
		_attack_executor.finished.disconnect(_on_attack_finished)

func _on_attack_finished() -> void:
	_disconnect_signals()
	
	var buffered_data = state_machine.query_buffered_action()
	if buffered_data and buffered_data.action == BufferComponent.BufferedAction.ATTACK:
		# Pega o PRÓXIMO ataque da lista.
		# Como avançamos o combo (via deferred), este getter deve retornar o próximo índice correto (2 ou 3).
		var next_profile = _air_combo_component.get_next_attack_profile()
		
		if not next_profile:
			next_profile = buffered_data.context.get("profile")

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
