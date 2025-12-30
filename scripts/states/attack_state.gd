class_name AttackState
extends State

var _attack_executor: AttackExecutor
var _current_profile: AttackProfile

enum InternalPhase { EXECUTING, RECOIL, LINK }
var _current_phase: InternalPhase
var _time_left_in_phase: float = 0.0
var _is_initialized: bool = false

# Nome do osso no Spine
const ROOT_BONE_NAME: String = "root"
const SPINE_SCALE_FACTOR: float = 1.0 

# Variável para calcular o delta de posição do osso
var _last_root_x: float = 0.0
# Flag para ignorar o "salto" causado pela transição de animação
var _ignore_next_frame: bool = false

func _initialize_references():
	if _is_initialized: return
	_attack_executor = owner_node.find_child("AttackExecutor")
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
	_current_phase = InternalPhase.EXECUTING
	
	# Prepara variáveis de controle
	_last_root_x = 0.0
	_ignore_next_frame = true # Ignora o primeiro frame para evitar o salto do Mix
	
	if _current_profile.movement_type == AttackProfile.MovementType.ROOT_MOTION:
		var sprite = owner_node.get_spine_sprite()
		if sprite:
			# Assumimos o controle do Update para garantir a ordem das coisas
			sprite.update_mode = SpineConstant.UpdateMode_Manual
			sprite.position = Vector2.ZERO # Reseta offset visual
			
			# HACK IMPRESCINDÍVEL:
			# Forçamos o Spine a limpar o Mix da animação anterior para esta
			# Isso impede que o 'Track Time' comece em 0.266 como mostrou seu log
			var entry = sprite.get_animation_state().get_current(0)
			if entry:
				entry.set_mix_duration(0)

	_attack_executor.execute(_current_profile)

func exit():
	if _attack_executor:
		_attack_executor.stop()
		if _attack_executor.is_connected("attack_phase_changed", Callable(self, "_on_attack_phase_changed")):
			_attack_executor.attack_phase_changed.disconnect(_on_attack_phase_changed)
		if _attack_executor.is_connected("finished", Callable(self, "_on_attack_finished")):
			_attack_executor.finished.disconnect(_on_attack_finished)

	owner_node.facing_locked = false
	_current_phase = InternalPhase.EXECUTING
	
	# Devolve o controle para o modo automático
	if _current_profile and _current_profile.movement_type == AttackProfile.MovementType.ROOT_MOTION:
		var sprite = owner_node.get_spine_sprite()
		if sprite:
			sprite.update_mode = SpineConstant.UpdateMode_Process
			sprite.position = Vector2.ZERO
			
	_current_profile = null
	_last_root_x = 0.0

func process_physics(delta: float, _walk_direction: float, _is_running: bool) -> Vector2:
	# Mantém a gravidade funcionando independente do resto
	var current_velocity = owner_node.velocity
	current_velocity = physics_component.apply_gravity(current_velocity, delta)
	
	# Se estivermos em Root Motion, processamos o movimento aqui e AGORA.
	# Não retornamos velocity.x para o CharacterBody, nós o movemos diretamente.
	if _current_phase == InternalPhase.EXECUTING and \
	   _current_profile and \
	   _current_profile.movement_type == AttackProfile.MovementType.ROOT_MOTION:
		
		_apply_root_motion_displacement(delta)
		current_velocity.x = 0.0 # A física padrão não deve empurrar o boneco, o Root Motion já empurrou
		return current_velocity

	# Lógica Padrão (Sem Root Motion)
	match _current_phase:
		InternalPhase.LINK:
			_time_left_in_phase -= delta
			if _time_left_in_phase <= 0.0:
				state_machine.on_current_state_finished()
				current_velocity.x = 0.0
				return current_velocity
			
			var move_vel = _current_profile.link_movement_velocity
			current_velocity.x = move_vel.x * owner_node.facing_sign
			if owner_node.is_on_floor(): current_velocity.y = move_vel.y
		
		InternalPhase.RECOIL:
			_time_left_in_phase -= delta
			if _time_left_in_phase <= 0.0: _on_attack_finished()
			var recoil_movement_x = -40.0
			current_velocity.x = recoil_movement_x * -owner_node.facing_sign
		
		InternalPhase.EXECUTING:
			if _attack_executor:
				if _current_profile.movement_type == AttackProfile.MovementType.PATH_TARGET:
					if path_follower_component and path_follower_component.is_active():
						if owner_node.is_on_floor():
							return path_follower_component.calculate_target_velocity(delta)
						else:
							current_velocity.x = 0.0
				else:
					# Movimento padrão via velocity
					current_velocity.x = _attack_executor.get_physics_movement_velocity().x

	return current_velocity

# --- NOVO SISTEMA DE MOVIMENTO DIRETO ---
func _apply_root_motion_displacement(delta: float):
	var sprite = owner_node.get_spine_sprite()
	if not sprite: return
	
	# 1. Atualiza a animação manualmente
	sprite.update_skeleton(delta)
	
	var skeleton = sprite.get_skeleton()
	var root_bone = skeleton.find_bone(ROOT_BONE_NAME)
	if not root_bone: return
	
	# 2. Pega a posição absoluta do osso na animação
	var current_root_x = root_bone.get_x()
	
	# 3. Se for o primeiro frame, apenas reseta a referência e zera o visual
	if _ignore_next_frame:
		_ignore_next_frame = false
		_last_root_x = current_root_x
		root_bone.set_x(0.0)
		skeleton.update_world_transform(0)
		return

	# 4. Calcula o DESLOCAMENTO (não velocidade)
	# Quantos pixels o osso andou desde o último frame?
	var displacement_x = (current_root_x - _last_root_x) * SPINE_SCALE_FACTOR
	
	# Atualiza referência para o próximo
	_last_root_x = current_root_x
	
	# 5. Move o corpo físico usando colisão (Kinematic)
	# Isso move o 'CharacterBody2D' e para se bater em parede
	if not is_zero_approx(displacement_x):
		var motion_vector = Vector2(displacement_x * owner_node.facing_sign, 0.0)
		# Nota: usamos move_and_collide para mover exatamente essa distância
		owner_node.move_and_collide(motion_vector)
	
	# 6. O Pulo do Gato Visual
	# O corpo físico andou 'displacement_x' para frente.
	# O sprite (filho) vai junto.
	# O osso (neto) também andou 'displacement_x' para frente na animação.
	# Resultado visual sem correção: O sprite anda 2x a distância.
	#
	# Correção: Zeramos o osso. O sprite volta para a origem do corpo físico.
	# Como o corpo físico já andou, o visual fica correto no mundo.
	root_bone.set_x(0.0)
	
	# 7. Aplica a correção visual no Spine antes de renderizar
	skeleton.update_world_transform(0) # 0 = PhysicsUpdateMode_None

# --- (Restante Inalterado) ---
func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	if _current_phase == InternalPhase.LINK:
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	var executor_phase = _attack_executor.get_current_phase_name()
	var in_startup = executor_phase == "STARTUP"
	var in_link_or_recoil = _current_phase == InternalPhase.LINK or _current_phase == InternalPhase.RECOIL
	
	if in_startup or in_link_or_recoil:
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	var executor_phase = _attack_executor.get_current_phase_name()
	var in_recovery = executor_phase == "RECOVERY"
	var in_link_or_recoil = _current_phase == InternalPhase.LINK or _current_phase == InternalPhase.RECOIL
	
	if in_recovery or in_link_or_recoil:
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
	
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)
	
func handle_dash_input(_profile: DashProfile) -> InputHandlerResult:
	var executor_phase = _attack_executor.get_current_phase_name()
	var in_recovery = executor_phase == "RECOVERY"
	var in_link_or_recoil = _current_phase == InternalPhase.LINK or _current_phase == InternalPhase.RECOIL
	
	if in_recovery or in_link_or_recoil:
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
	
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_attack_outcome(result: ContactResult):
	if result.attacker_outcome == ContactResult.AttackerOutcome.ATTACK_BLOCKED or result.attacker_outcome == ContactResult.AttackerOutcome.HIT_SUCCESS_SIMPLE_ENEMY:
		if _current_phase == InternalPhase.EXECUTING:
			_attack_executor.stop()
			_current_phase = InternalPhase.RECOIL
			_time_left_in_phase = _current_profile.get("block_recoil_duration")


func resolve_contact(context: ContactContext) -> ContactResult:
	var executor_phase = _attack_executor.get_current_phase_name()

	if executor_phase == "RECOVERY" or _current_phase != InternalPhase.EXECUTING:
		return _resolve_default_contact(context)
	else:
		if context.attacker_node is SimpleEnemy and not context.attacker_node.is_in_group("Environment"):
			var ignored_result = ContactResult.new()
			ignored_result.attacker_node = context.attacker_node
			ignored_result.defender_node = context.defender_node
			ignored_result.attack_profile = context.attack_profile
			
			ignored_result.defender_outcome = ContactResult.DefenderOutcome.NONE
			ignored_result.attacker_outcome = ContactResult.AttackerOutcome.NONE
			
			return ignored_result
			
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

	if _current_phase != InternalPhase.EXECUTING:
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
	_current_phase = InternalPhase.LINK
	_time_left_in_phase = _current_profile.link_duration
	if state_machine.buffer_component.has_buffer():
		state_machine.on_current_state_finished()
		return
	else:
		_current_phase = InternalPhase.LINK
		_time_left_in_phase = _current_profile.link_duration
