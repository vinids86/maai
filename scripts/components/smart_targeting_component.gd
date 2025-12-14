extends Node2D
class_name SmartTargetingComponent

## Referência ao perfil de Dash para acessar distâncias e ângulos.
@export var profile: DashProfile

## O alvo que está atualmente selecionado e pronto para receber o dash.
var current_target: Node2D = null

## O último alvo utilizado, usado para lógica de bloqueio (não voltar imediatamente).
var last_used_target: Node2D = null

## Referência ao ator (Player) para cálculos de posição relativa.
var _actor: Node2D

func _ready() -> void:
	_actor = get_parent()
	# Garante que o ator seja um Node2D válido para cálculos de posição
	while _actor and not _actor is Node2D:
		_actor = _actor.get_parent()

func _physics_process(_delta: float) -> void:
	if not _actor or not profile:
		return
	
	# Captura o input de movimento para determinar a direção da mira
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	_update_targeting(input_vector)

## Limpa o histórico de alvo usado (chamar quando o player tocar o chão).
func reset_history() -> void:
	last_used_target = null

## Registra o alvo atual como usado (chamar ao confirmar o dash).
func commit_target() -> void:
	if profile.same_target_lockout:
		last_used_target = current_target

## Lógica principal de busca e seleção de alvos.
func _update_targeting(input_dir: Vector2) -> void:
	var new_target = _find_best_target(input_dir)
	
	# Atualiza o destaque visual apenas se o alvo mudar
	if new_target != current_target:
		if is_instance_valid(current_target) and current_target.has_method("highlight"):
			current_target.highlight(false)
		
		current_target = new_target
		
		if is_instance_valid(current_target) and current_target.has_method("highlight"):
			current_target.highlight(true)

## Calcula matematicamente o melhor candidato baseado em distância e ângulo.
func _find_best_target(input_dir: Vector2) -> Node2D:
	# Se o input for muito fraco (zona morta), não busca nada
	if input_dir.length_squared() < 0.1:
		return null
		
	var tokens = get_tree().get_nodes_in_group("Tokens")
	var best_token: Node2D = null
	var closest_dist: float = profile.max_distance
	var actor_pos = _actor.global_position
	
	for token in tokens:
		# Pula se for o último token usado e o lockout estiver ativo
		if token == last_used_target:
			continue
			
		var to_token = token.global_position - actor_pos
		var dist = to_token.length()
		
		# Filtro de Distância
		if dist > profile.max_distance:
			continue
			
		# Filtro de Direção (Dot Product)
		var dir_to_token = to_token.normalized()
		var alignment = input_dir.dot(dir_to_token)
		
		# Verifica se está dentro do cone de visão definido no profile
		if alignment > profile.detection_cone:
			# Prioriza o mais próximo dentro do cone
			if dist < closest_dist:
				closest_dist = dist
				best_token = token
				
	return best_token
