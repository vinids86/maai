class_name SimplePatrolFlyState
extends SimpleState

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
## Frequência da onda (velocidade da oscilação).
@export var wave_frequency: float = 5.0
## Amplitude da onda (largura da oscilação).
@export var wave_amplitude: float = 150.0

var _target_pos: Vector2
var _pos_a: Vector2
var _pos_b: Vector2
var _going_to_a: bool = false
var _time_accum: float = 0.0

func enter(_args: Dictionary = {}):
	_time_accum = 0.0
	
	# Captura as posições globais dos Markers.
	# CORREÇÃO: Usamos get_node_or_null() diretamente (no self), pois o NodePath 
	# salvo no Inspetor é relativo a este nó de Estado, e não ao Inimigo (owner_node).
	var node_a = get_node_or_null(point_a_node)
	var node_b = get_node_or_null(point_b_node)
	
	if node_a and node_b:
		_pos_a = node_a.global_position
		_pos_b = node_b.global_position
	else:
		push_warning("SimplePatrolFlyState: Pontos A ou B não encontrados! Verifique os caminhos no Inspetor. Usando fallback.")
		_pos_a = owner_node.global_position
		_pos_b = owner_node.global_position + Vector2(200, 0) # Fallback padrão
	
	# Define o alvo inicial como o mais próximo ou sempre o B
	_target_pos = _pos_b
	_going_to_a = false

func process_physics(delta: float) -> Vector2:
	_time_accum += delta
	
	var current_pos = owner_node.global_position
	var distance = current_pos.distance_to(_target_pos)
	
	# 1. Verifica se chegou ao destino
	if distance < arrival_threshold:
		_switch_target()
	
	# 2. Calcula vetor de direção normalizado (Para onde ir)
	var direction = (current_pos.direction_to(_target_pos)).normalized()
	
	# 3. Calcula velocidade linear base
	var linear_velocity = direction * fly_speed
	
	# 4. Calcula a Onda (Senoide)
	# Precisamos de um vetor perpendicular à direção do movimento para aplicar a onda "de lado"
	# Se a direção é (x, y), a perpendicular é (-y, x)
	var perpendicular = Vector2(-direction.y, direction.x)
	
	# Usamos cosseno aqui para afetar a velocidade e gerar uma senoide na posição
	var wave_velocity = perpendicular * cos(_time_accum * wave_frequency) * wave_amplitude
	
	# 5. Soma as velocidades
	var final_velocity = linear_velocity + wave_velocity
	
	# 6. Orientação do Sprite (Facing)
	# Só vira se houver movimento horizontal significativo
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
