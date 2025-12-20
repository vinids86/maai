class_name SimplePatrolFlyState
extends SimpleState

## Estado de Patrulha Aérea.
## Move o inimigo entre dois pontos (Markers) com movimento senoidal (onda).
## A detecção do player é feita externamente pela AggressiveStateMachine.

@export_group("Patrol Points")
## Caminho para o nó Marker2D que representa o Ponto A.
@export var point_a_node: NodePath
## Caminho para o nó Marker2D que representa o Ponto B.
@export var point_b_node: NodePath
## Distância mínima para considerar que chegou no ponto e trocar o alvo.
@export var arrival_threshold: float = 10.0

@export_group("Flight Physics")
## Velocidade de deslocamento entre os pontos.
@export var fly_speed: float = 150.0
## Frequência da onda (velocidade da oscilação para cima/baixo).
@export var wave_frequency: float = 5.0
## Amplitude da onda (altura da oscilação).
@export var wave_amplitude: float = 150.0

var _target_pos: Vector2
var _pos_a: Vector2
var _pos_b: Vector2
var _going_to_a: bool = false
var _time_accum: float = 0.0

func enter(_args: Dictionary = {}):
	_time_accum = 0.0
	
	# Garante que temos posições válidas
	var node_a = get_node_or_null(point_a_node)
	var node_b = get_node_or_null(point_b_node)
	
	if node_a and node_b:
		_pos_a = node_a.global_position
		_pos_b = node_b.global_position
	else:
		# Fallback se esquecer de configurar os nós: patrulha 200px para a direita
		if owner_node:
			_pos_a = owner_node.global_position
			_pos_b = owner_node.global_position + Vector2(200, 0)
	
	# Define destino inicial (vai para B primeiro por padrão)
	_target_pos = _pos_b
	_going_to_a = false
	
	state_machine.emit_phase_change({
		"state": "SimplePatrolFlyState",
		"phase": "patrol",
		"animation_to_play": "run"
	})

func process_physics(delta: float) -> Vector2:
	_time_accum += delta
	
	var current_pos = owner_node.global_position
	var distance = current_pos.distance_to(_target_pos)
	
	# 1. Verifica chegada ao destino
	if distance < arrival_threshold:
		_switch_target()
	
	# 2. Calcula movimento
	var direction = (current_pos.direction_to(_target_pos)).normalized()
	
	# Velocidade linear
	var linear_velocity = direction * fly_speed
	
	# Velocidade da onda (perpendicular ao movimento)
	var perpendicular = Vector2(-direction.y, direction.x)
	var wave_velocity = perpendicular * cos(_time_accum * wave_frequency) * wave_amplitude
	
	var final_velocity = linear_velocity + wave_velocity
	
	# 3. Orientação (Facing)
	if abs(direction.x) > 0.1:
		_flip_owner(sign(direction.x))
		
	return final_velocity

func _switch_target():
	_going_to_a = !_going_to_a
	if _going_to_a:
		_target_pos = _pos_a
	else:
		_target_pos = _pos_b

func _flip_owner(dir_sign: float):
	if owner_node.has_method("set_facing_direction"):
		owner_node.set_facing_direction(dir_sign)
