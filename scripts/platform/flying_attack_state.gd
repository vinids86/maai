class_name FlyingAttackState
extends SimpleState

## Estado de Ataque Aéreo (Swoop/Dash).
## Inclui lógica de "Telegraphing" e manutenção de altitude nas fases de preparação/recuperação.

enum Phases { STARTUP, ACTIVE, RECOVERY }

@export_group("Combat Fairness")
## Tempo antes do ataque sair em que a mira para de seguir o player (Trava a direção).
@export var lock_direction_time: float = 0.2

@export_group("Altitude Control")
## Altura mínima que o inimigo tenta manter do chão (durante Startup/Recovery).
@export var min_altitude: float = 150.0
## Força com que ele sobe para evitar o chão.
@export var floor_avoidance_force: float = 300.0
## Máscara de colisão do mundo para detectar o chão.
@export_flags_2d_physics var ground_collision_mask: int = 1

var _current_phase: Phases = Phases.STARTUP
var _time_left: float = 0.0
var _profile: AttackProfile
var _attack_velocity_vector: Vector2 = Vector2.ZERO

func enter(_args: Dictionary = {}):
	if owner_node.has_method("get_attack_profile"):
		_profile = owner_node.get_attack_profile()
	
	if not _profile:
		state_machine.on_current_state_finished({"outcome": "ATTACK_FINISHED"})
		return
	
	owner_node.velocity = Vector2.ZERO
	_attack_velocity_vector = Vector2.ZERO
	_change_phase(Phases.STARTUP)

func process_physics(delta: float) -> Vector2:
	if not _profile: return Vector2.ZERO
		
	_time_left -= delta
	
	if _time_left <= 0:
		_advance_phase()
		# Evita picos de movimento na transição de frame
		if _current_phase != Phases.ACTIVE: 
			return Vector2.ZERO 
	
	# Calcula a velocidade base do estado
	var desired_velocity = Vector2.ZERO
	
	match _current_phase:
		Phases.STARTUP:
			if _time_left > lock_direction_time:
				_update_aiming_vector()
			desired_velocity = Vector2.ZERO
			
		Phases.ACTIVE:
			desired_velocity = _attack_velocity_vector
			
		Phases.RECOVERY:
			var current_vel = owner_node.velocity
			desired_velocity = current_vel.move_toward(Vector2.ZERO, 800.0 * delta)
	
	# --- CORREÇÃO DE ALTITUDE ---
	# Só aplica força para subir se NÃO estiver atacando ativamente (mergulhando)
	if _current_phase != Phases.ACTIVE:
		var space_state = owner_node.get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(
			owner_node.global_position, 
			owner_node.global_position + Vector2.DOWN * min_altitude,
			ground_collision_mask
		)
		query.exclude = [owner_node.get_rid()] 
		
		var result = space_state.intersect_ray(query)
		if result:
			var dist_to_floor = owner_node.global_position.distance_to(result.position)
			var avoidance_strength = 1.0 - (dist_to_floor / min_altitude)
			# Adiciona força vertical à velocidade desejada
			desired_velocity.y += -floor_avoidance_force * avoidance_strength
			
	return desired_velocity

func _advance_phase():
	match _current_phase:
		Phases.STARTUP:
			if _attack_velocity_vector == Vector2.ZERO:
				_update_aiming_vector()
			_change_phase(Phases.ACTIVE)
		Phases.ACTIVE:
			_change_phase(Phases.RECOVERY)
		Phases.RECOVERY:
			state_machine.on_current_state_finished({"outcome": "ATTACK_FINISHED"})

func _update_aiming_vector():
	var target_pos = Vector2.ZERO
	
	if is_instance_valid(GameManager.player_node):
		target_pos = GameManager.player_node.global_position
	else:
		var facing = 1.0
		if owner_node.has_method("get_facing_direction"):
			facing = owner_node.get_facing_direction()
		target_pos = owner_node.global_position + (Vector2.RIGHT * facing * 100)
	
	var direction = (target_pos - owner_node.global_position).normalized()
	var speed = _profile.active_movement_velocity.x
	if speed <= 0: speed = 600.0
	
	_attack_velocity_vector = direction * speed
	
	if abs(direction.x) > 0.1:
		_flip_owner(sign(direction.x))

func _change_phase(new_phase: Phases):
	_current_phase = new_phase
	
	var duration = 0.0
	var sfx: AudioStream
	var anim_name: StringName = &""
	
	match _current_phase:
		Phases.STARTUP:
			duration = _profile.startup_duration
			sfx = _profile.startup_sfx
			anim_name = _profile.animation_name 
		Phases.ACTIVE:
			duration = _profile.active_duration
			sfx = _profile.active_sfx
		Phases.RECOVERY:
			duration = _profile.recovery_duration
			sfx = _profile.recovery_sfx
			
	_time_left = duration
	
	state_machine.emit_phase_change({
		"state": "FlyingAttackState",
		"phase": Phases.keys()[_current_phase],
		"profile": _profile,
		"animation_to_play": anim_name,
		"sfx_to_play": sfx
	})

func _flip_owner(dir_sign: float):
	if owner_node.has_method("set_facing_direction"):
		owner_node.set_facing_direction(dir_sign)
