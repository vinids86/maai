class_name DashState
extends State

@export var targeting_component: SmartTargetingComponent

var current_profile: DashProfile

enum Phases { ACTIVE, RECOVERY, ATTACKING }
var current_phase: Phases
var time_left_in_phase: float = 0.0

var _attack_executor: AttackExecutor
var _is_initialized: bool = false

# Armazena a direção fixa do dash (para não virar no meio)
var _dash_direction: int = 1
# Velocidade calculada atual
var _current_velocity: Vector2 = Vector2.ZERO

# Variáveis do Modo Grapple
var _is_grapple_mode: bool = false
var _target_pos: Vector2
var _grapple_dist: float = 0.0

func _initialize_references():
	if _is_initialized:
		return
	_attack_executor = owner_node.find_child("AttackExecutor")
	# targeting_component já deve vir do inspector ou ser buscado se necessário
	if not targeting_component:
		targeting_component = owner_node.find_child("SmartTargetingComponent")
	
	assert(_attack_executor != null, "DashState: Nó 'AttackExecutor' não encontrado.")
	_is_initialized = true

func enter(args: Dictionary = {}):
	_initialize_references()
	
	self.current_profile = args.get("profile")
	if not current_profile:
		state_machine.on_current_state_finished()
		return

	# --- DECISÃO DE MODO ---
	# Prioridade: Grapple se tiver alvo válido
	if targeting_component and targeting_component.current_target:
		_start_grapple_dash()
	else:
		_start_classic_dash()

	# Bloqueia a direção do sprite
	owner_node.facing_locked = true
	_dash_direction = owner_node.facing_sign
	
	_change_phase(Phases.ACTIVE)

func _start_grapple_dash() -> void:
	_is_grapple_mode = true
	var target = targeting_component.current_target
	_target_pos = target.global_position
	targeting_component.commit_target()
	
	# Calcula distância inicial para usar no progresso se quiser curva, 
	# ou apenas para debug.
	_grapple_dist = (_target_pos - owner_node.global_position).length()

func _start_classic_dash() -> void:
	_is_grapple_mode = false

func exit():
	owner_node.facing_locked = false
	_current_velocity = Vector2.ZERO
	_is_grapple_mode = false

	if _attack_executor and current_phase == Phases.ATTACKING:
		_attack_executor.stop()
		if _attack_executor.is_connected("finished", Callable(self, "_on_attack_finished")):
			_attack_executor.finished.disconnect(_on_attack_finished)
		if _attack_executor.is_connected("attack_phase_changed", Callable(self, "_on_phase_changed")):
			_attack_executor.attack_phase_changed.disconnect(_on_phase_changed)

func process_physics(delta: float, _walk_direction: float, _is_running: bool) -> Vector2:
	if not current_profile:
		return Vector2.ZERO

	match current_phase:
		Phases.ACTIVE:
			if _is_grapple_mode:
				_process_grapple_movement(delta)
			else:
				_process_active_movement(delta)
		Phases.RECOVERY:
			_process_recovery_movement(delta)
		Phases.ATTACKING:
			if _attack_executor:
				_current_velocity = _attack_executor.get_physics_movement_velocity()

	# No modo Grapple, o tempo é controlado pela distância/chegada, 
	# mas usamos o timer como segurança (timeout).
	time_left_in_phase -= delta
	_check_phase_transition()
	
	# Aplica gravidade APENAS se não estiver no modo Grapple
	# No modo Grapple, queremos voo livre direto ao alvo.
	if not _is_grapple_mode and not owner_node.is_on_floor():
		_current_velocity = physics_component.apply_gravity(_current_velocity, delta)
	
	return _current_velocity

func _process_grapple_movement(_delta: float):
	var to_target = _target_pos - owner_node.global_position
	var dist = to_target.length()
	
	# Se chegou perto o suficiente, forçamos o fim da fase ativa
	if dist < current_profile.arrival_tolerance:
		# Reset de ações aéreas ao conectar no token
		if owner_node.has_method("reset_air_actions"):
			owner_node.reset_air_actions()
			
		time_left_in_phase = 0 # Força transição no próximo _check_phase_transition
		
		# Aplica impulso de saída (Auto Jump)
		_current_velocity = Vector2.ZERO
		_current_velocity.y = current_profile.auto_jump_force
		return

	# Movimento direto
	_current_velocity = to_target.normalized() * current_profile.travel_speed

func _process_active_movement(_delta: float):
	# Calcula o progresso normalizado de 0.0 a 1.0 (0 = inicio, 1 = fim)
	var progress = 1.0 - (time_left_in_phase / current_profile.active_duration)
	progress = clamp(progress, 0.0, 1.0)
	
	# Velocidade Média necessária = Distância / Tempo
	var average_speed = current_profile.dash_distance / current_profile.active_duration
	
	# Aplica o multiplicador da curva se ela existir
	var speed_multiplier = 1.0
	if current_profile.speed_curve:
		speed_multiplier = current_profile.speed_curve.sample(progress)
	
	var speed_x = average_speed * speed_multiplier * _dash_direction
	_current_velocity.x = speed_x
	_current_velocity.y = 0 # Dash terrestre geralmente zera o Y

func _process_recovery_movement(delta: float):
	# Aplica fricção/desaceleração suave baseada no valor configurado no profile
	_current_velocity.x = move_toward(_current_velocity.x, 0, current_profile.recovery_friction * delta)

func _check_phase_transition():
	if time_left_in_phase <= 0:
		if current_phase == Phases.ACTIVE:
			_change_phase(Phases.RECOVERY)
		elif current_phase == Phases.RECOVERY:
			var buffered_data = state_machine.query_buffered_action()
			if buffered_data and buffered_data.action == BufferComponent.BufferedAction.ATTACK:
				_start_dash_attack(buffered_data.context.get("profile"))
			else:
				state_machine.on_current_state_finished()

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	var dash_attack_profile = owner_node.dash_attack_profile
	if not dash_attack_profile:
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

	# Permite cancelar o dash para um ataque a qualquer momento
	if current_phase == Phases.ACTIVE or current_phase == Phases.RECOVERY:
		var context = {"override_profile": dash_attack_profile}
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED, context)
		
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func resolve_contact(context: ContactContext) -> ContactResult:
	return _resolve_default_contact(context)

func get_poise_shield_contribution() -> float:
	if current_phase == Phases.ATTACKING:
		var profile = _attack_executor.get_current_profile()
		if profile:
			match _attack_executor.get_current_phase_name():
				"STARTUP": return profile.startup_poise_shield
				"ACTIVE": return profile.active_poise_shield
				"RECOVERY": return profile.recovery_poise_shield
	return 0.0

func _change_phase(new_phase: Phases):
	current_phase = new_phase
	var animation_to_play: String
	var sfx_to_play: AudioStream
	match current_phase:
		Phases.ACTIVE:
			animation_to_play = current_profile.animation_name
			# Se for Grapple, o tempo é um timeout de segurança (ex: 1s),
			# a saída real é por distância.
			if _is_grapple_mode:
				if current_profile.travel_speed > 0:
					time_left_in_phase = (current_profile.max_distance / current_profile.travel_speed) + 0.5
				else:
					time_left_in_phase = 1.0
			else:
				time_left_in_phase = current_profile.active_duration
			
			sfx_to_play = current_profile.active_sfx
			
		Phases.RECOVERY:
			# Recuperação é igual para ambos (ou zero se quiser chain rápido no grapple)
			time_left_in_phase = current_profile.recovery_duration
			sfx_to_play = current_profile.recovery_sfx
			
		Phases.ATTACKING:
			return

	var phase_data = {
		"state_name": self.name,
		"phase_name": Phases.keys()[current_phase],
		"profile": current_profile,
		"animation_to_play": animation_to_play,
		"sfx_to_play": sfx_to_play
	}
	
	# Adiciona o target ao phase_data apenas se estiver no modo Grapple
	if _is_grapple_mode and targeting_component and targeting_component.current_target:
		phase_data["target_node"] = targeting_component.current_target
		
	state_machine.emit_phase_change(phase_data)

func _start_dash_attack(profile: AttackProfile):
	if not profile or not state_machine.action_cost_validator.try_pay_costs(profile):
		state_machine.on_current_state_finished()
		return
	
	_change_phase(Phases.ATTACKING)
	_attack_executor.attack_phase_changed.connect(_on_phase_changed)
	_attack_executor.finished.connect(_on_attack_finished)
	_attack_executor.execute(profile)
	
func _on_phase_changed(phase_data: Dictionary):
	state_machine.emit_phase_change(phase_data)
	
func _on_attack_finished():
	state_machine.on_current_state_finished()
