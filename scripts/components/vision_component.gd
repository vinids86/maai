class_name VisionComponent
extends Node2D

## Componente responsável por verificar se há obstáculos entre o dono e o alvo.
## Deve ser adicionado como filho do Inimigo.

# A camada de colisão que representa paredes/obstáculos.
# No Godot padrão, Layer 1 costuma ser o World/Terrain. Ajuste conforme seu projeto.
@export_flags_2d_physics var obstacle_mask: int = 1

# Opcional: Referência ao próprio corpo para ignorá-lo no raio (evita colidir com a própria hitbox)
@onready var owner_body: CollisionObject2D = get_parent() as CollisionObject2D

## Retorna TRUE se houver uma linha limpa até o alvo.
## Retorna FALSE se houver uma parede no caminho.
func can_see_target(target: Node2D) -> bool:
	if not target:
		return false
		
	# 1. Prepara o "Espaço Físico" para a consulta
	var space_state = get_world_2d().direct_space_state
	
	# Ponto de origem (geralmente os olhos ou centro do inimigo)
	var origin_pos = global_position
	# Ponto de destino (centro do alvo)
	var target_pos = target.global_position
	
	# 2. Cria a configuração do Raio (RayQuery)
	var query = PhysicsRayQueryParameters2D.create(origin_pos, target_pos)
	
	# Configura para colidir APENAS com a máscara de obstáculos definida no Inspector
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = obstacle_mask
	
	# Ignora o próprio inimigo para o raio não bater nele mesmo ao sair
	if owner_body:
		query.exclude = [owner_body.get_rid()]
		
	# 3. Lança o raio
	var result = space_state.intersect_ray(query)
	
	# Lógica de Retorno:
	if result:
		# Se o raio "intersectou" algo usando a máscara de obstáculos,
		# significa que bateu em uma parede antes de chegar no destino final.
		# Logo, NÃO temos visão.
		return false
	else:
		# Se o raio não bateu em nada (na máscara de obstáculos), o caminho está livre.
		return true
