class_name FlyingChaseState
extends SimpleState

## Estado de perseguição para voadores com movimento oscilatório e manutenção de altitude.

@export_group("Flight Physics")
## Velocidade base de deslocamento em direção ao player.
@export var fly_speed: float = 200.0
## Frequência da onda (velocidade da oscilação).
@export var wave_frequency: float = 5.0
## Amplitude da onda (largura/força da oscilação lateral).
@export var wave_amplitude: float = 150.0

@export_group("Altitude Control")
## Altura mínima que o inimigo tenta manter do chão.
@export var min_altitude: float = 150.0
## Força com que ele sobe para evitar o chão (suaviza a subida).
@export var floor_avoidance_force: float = 300.0
## Máscara de colisão do mundo (Layers) para detectar o chão.
@export_flags_2d_physics var ground_collision_mask: int = 1

var _aggressive_sm: AggressiveStateMachine
var _time_accum: float = 0.0

func enter(_args: Dictionary = {}):
	_aggressive_sm = state_machine as AggressiveStateMachine
	_time_accum = 0.0
	
	state_machine.emit_phase_change({
		"state": "FlyingChaseState",
		"phase": "chase",
		"animation_to_play": "run"
	})

func process_physics(delta: float) -> Vector2:
	var player = GameManager.player_node
	
	if not is_instance_valid(player) or not _aggressive_sm:
		state_machine.on_current_state_finished({"outcome": "LOST_TARGET"})
		return Vector2.ZERO
		
	var to_player = player.global_position - owner_node.global_position
	var dist = to_player.length()
	
	# --- 1. Lógica de Decisão ---
	if dist <= _aggressive_sm.attack_range:
		state_machine.on_current_state_finished({"outcome": "CHASE_FINISHED"})
		return owner_node.velocity 
		
	if dist > _aggressive_sm.detection_range * 1.5:
		state_machine.on_current_state_finished({"outcome": "LOST_TARGET"})
		return Vector2.ZERO
	
	# --- 2. Física de Voo ---
	_time_accum += delta
	
	var direction = to_player.normalized()
	var linear_velocity = direction * fly_speed
	
	# Onda Senoidal
	var perpendicular = Vector2(-direction.y, direction.x)
	var wave_velocity = perpendicular * cos(_time_accum * wave_frequency) * wave_amplitude
	
	# Soma as velocidades base
	var final_velocity = linear_velocity + wave_velocity
	
	# --- 3. Correção de Altitude (Raycast) ---
	# Verifica se há chão logo abaixo
	var space_state = owner_node.get_world_2d().direct_space_state
	# Cria uma linha do inimigo para baixo até a altitude mínima
	var query = PhysicsRayQueryParameters2D.create(
		owner_node.global_position, 
		owner_node.global_position + Vector2.DOWN * min_altitude,
		ground_collision_mask
	)
	# Ignora o próprio inimigo para não colidir consigo mesmo
	query.exclude = [owner_node.get_rid()] 
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# Se detectou chão, calcula uma força para cima
		# Quanto mais perto do chão, mais forte a força (proporcional)
		var dist_to_floor = owner_node.global_position.distance_to(result.position)
		var avoidance_strength = 1.0 - (dist_to_floor / min_altitude) # 0 a 1
		
		# Aplica força para cima baseada na proximidade
		final_velocity.y += -floor_avoidance_force * avoidance_strength
	
	# --- 4. Orientação ---
	if abs(direction.x) > 0.1:
		_flip_owner(sign(direction.x))
		
	return final_velocity

func _flip_owner(dir_sign: float):
	if owner_node.has_method("set_facing_direction"):
		owner_node.set_facing_direction(dir_sign)
