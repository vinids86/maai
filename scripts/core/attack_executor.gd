class_name AttackExecutor
extends Node

signal attack_phase_changed(phase_data: Dictionary)
signal finished

# --- Definição dos Eventos do Spine ---
const EVENT_PHASE_ACTIVE = "PHASE_ACTIVE"
const EVENT_PHASE_RECOVERY = "PHASE_RECOVERY"

var _owner_node: Node
var _hitbox: Area2D
var _hitbox_shape: CollisionShape2D
var _projectile_spawn_point: Marker2D
var _current_profile: AttackProfile
var _path_follower_component: PathFollowerComponent
var _path_target: Node2D
var _spine_sprite: SpineSprite # Referência para escutar eventos

enum Phases { STARTUP, ACTIVE, RECOVERY, NONE }
var _current_phase: Phases = Phases.NONE

func _ready():
	set_physics_process(false)

func setup(owner: Node):
	self._owner_node = owner
	
	# --- Lógica de busca original preservada ---
	_hitbox = owner.find_child("AttackHitbox") as Area2D
	if _hitbox:
		_hitbox_shape = _hitbox.find_child("CollisionShape2D") as CollisionShape2D
	
	_projectile_spawn_point = owner.find_child("ProjectileSpawnPoint") as Marker2D
	_path_follower_component = owner.find_child("PathFollowerComponent")
	# Assumindo que PathTarget é irmão do owner, como no original
	if owner.get_parent().has_node("PathTarget"):
		_path_target = owner.get_parent().get_node("PathTarget")
	
	_spine_sprite = owner.get_spine_sprite()
		
	assert(_spine_sprite != null, "AttackExecutor: SpineSprite não encontrado no Owner.")
	
	# Conexão dos sinais do Spine (Evita conexões duplicadas)
	if not _spine_sprite.animation_event.is_connected(_on_spine_animation_event):
		_spine_sprite.animation_event.connect(_on_spine_animation_event)
	if not _spine_sprite.animation_completed.is_connected(_on_spine_animation_completed):
		_spine_sprite.animation_completed.connect(_on_spine_animation_completed)

	assert(_hitbox != null, "AttackExecutor: Nó 'AttackHitbox' não encontrado.")
	assert(_hitbox_shape != null, "AttackExecutor: Nó 'CollisionShape2D' não encontrado.")

func execute(profile: AttackProfile):
	if not is_instance_valid(profile):
		push_warning("AttackExecutor: Tentou executar um AttackProfile inválido.")
		return
	
	self._current_profile = profile
	
	if _current_profile.movement_type == AttackProfile.MovementType.PATH_TARGET and _path_follower_component and _path_target:
		_path_target.position = Vector2.ZERO
		_path_follower_component.start_following(_path_target)

	_change_phase(Phases.STARTUP)

# Função pública para parar o ataque externamente (ex: tomar dano, cancelar)
func stop():
	_stop_execution()

# --- HANDLERS DE EVENTOS DO SPINE ---

func _on_spine_animation_event(sprite: SpineSprite, animation_state: SpineAnimationState, track_entry: SpineTrackEntry, event: SpineEvent):
	# Segurança: Só processa eventos se estivermos executando um ataque e for a animação correta
	if _current_phase == Phases.NONE or not _current_profile:
		return
		
	if track_entry.get_animation().get_name() != _current_profile.animation_name:
		return

	var event_name = event.get_data().get_event_name()
	
	match event_name:
		EVENT_PHASE_ACTIVE:
			_change_phase(Phases.ACTIVE)
		EVENT_PHASE_RECOVERY:
			_change_phase(Phases.RECOVERY)

func _on_spine_animation_completed(sprite: SpineSprite, animation_state: SpineAnimationState, track_entry: SpineTrackEntry):
	# Se a animação do ataque acabou, encerra o ataque
	if _current_profile and track_entry.get_animation().get_name() == _current_profile.animation_name:
		_stop_execution()
		emit_signal("finished")

# ------------------------------------

func get_current_profile() -> AttackProfile:
	return _current_profile

func get_current_phase_name() -> String:
	return Phases.keys()[_current_phase].to_upper()

func get_physics_movement_velocity() -> Vector2:
	if _current_phase == Phases.NONE or not _current_profile or _current_profile.movement_type != AttackProfile.MovementType.PHYSICS:
		return Vector2.ZERO
		
	var move_vel = Vector2.ZERO
	match _current_phase:
		Phases.STARTUP:
			move_vel = _current_profile.startup_movement_velocity
		Phases.ACTIVE:
			move_vel = _current_profile.active_movement_velocity
		Phases.RECOVERY:
			move_vel = _current_profile.recovery_movement_velocity
	
	var final_velocity = Vector2.ZERO
	if "facing_sign" in _owner_node:
		final_velocity.x = move_vel.x * _owner_node.facing_sign
	else:
		final_velocity.x = move_vel.x
		
	final_velocity.y = move_vel.y
	return final_velocity

func _stop_execution():
	if _current_profile and _current_profile.movement_type == AttackProfile.MovementType.PATH_TARGET:
		if _path_follower_component:
			_path_follower_component.stop_following()

	set_physics_process(false)
	_current_phase = Phases.NONE
	_current_profile = null
	
	if _hitbox_shape and is_instance_valid(_hitbox_shape):
		_hitbox_shape.set_deferred("disabled", true)
		_hitbox_shape.shape = null
	
	if is_instance_valid(_hitbox):
		_hitbox.position = Vector2.ZERO
		_hitbox.scale = Vector2.ONE
		_hitbox.source_node = null

func _change_phase(new_phase: Phases):
	_current_phase = new_phase
	
	var sfx_to_play: AudioStream
	match _current_phase:
		Phases.STARTUP:
			# _time_left_in_phase removido
			sfx_to_play = _current_profile.startup_sfx
			# Garante hitbox desligada no inicio
			if _hitbox_shape:
				_hitbox_shape.set_deferred("disabled", true)
				
		Phases.ACTIVE:
			# _time_left_in_phase removido
			sfx_to_play = _current_profile.active_sfx
			
			# LÓGICA DE DECISÃO: Ranged vs Melee (Mantida original)
			if _current_profile.projectile_scene:
				_spawn_projectile()
			else:
				_update_and_enable_hitbox()
				
		Phases.RECOVERY:
			# _time_left_in_phase removido
			sfx_to_play = _current_profile.recovery_sfx
			# Desativa hitbox ao entrar em recovery (Mantido original)
			if _hitbox_shape:
				_hitbox_shape.set_deferred("disabled", true)
				_hitbox_shape.shape = null
	
	var phase_data: Dictionary = {
		"state_name": _owner_node.state_machine.current_state.name if "state_machine" in _owner_node else "Unknown",
		"phase_name": get_current_phase_name(),
		"profile": _current_profile,
		"sfx_to_play": sfx_to_play
	}
	
	# Só manda o nome da animação no Startup para iniciar o playback
	if _current_phase == Phases.STARTUP:
		phase_data["animation_to_play"] = _current_profile.animation_name
	
	emit_signal("attack_phase_changed", phase_data)

func _spawn_projectile() -> void:
	# --- LÓGICA MANTIDA IDÊNTICA AO ORIGINAL ---
	var scene = _current_profile.projectile_scene
	var projectile = scene.instantiate() as Projectile
	
	if not projectile:
		push_error("AttackExecutor: Cena configurada não é um Projectile válido.")
		return

	var spawn_pos = _owner_node.global_position
	if _projectile_spawn_point:
		spawn_pos = _projectile_spawn_point.global_position
	else:
		var offset = _current_profile.hitbox_position
		if "facing_sign" in _owner_node:
			offset.x *= _owner_node.facing_sign
		spawn_pos += offset

	var shoot_dir = Vector2.RIGHT
	if "facing_sign" in _owner_node:
		shoot_dir.x = _owner_node.facing_sign

	get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_pos
	
	projectile.setup(_owner_node, _current_profile, shoot_dir)

func _update_and_enable_hitbox():
	# --- LÓGICA MANTIDA IDÊNTICA AO ORIGINAL ---
	_hitbox.attack_profile = _current_profile
	
	_hitbox.source_node = _owner_node 
	
	# Usando hitbox_size do profile, como no seu código original
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = _current_profile.hitbox_size
	
	_hitbox_shape.shape = shape
	
	# Usando hitbox_position do profile, como no seu código original
	_hitbox.position = _current_profile.hitbox_position
	if "facing_sign" in _owner_node:
		_hitbox.position.x *= _owner_node.facing_sign
		# Se necessário espelhar a escala do Area2D, mantive sua lógica:
		_hitbox.scale.x = _owner_node.facing_sign
	
	_hitbox_shape.set_deferred("disabled", false)
