class_name MovementComponent
extends Node

# --- REFERÊNCIAS ---
var owner_node: CharacterBody2D

func _ready():
	# Guardamos uma referência ao corpo do personagem para evitar chamadas repetidas a get_parent().
	owner_node = get_parent()
	assert(owner_node is CharacterBody2D, "MovementComponent deve ser filho de um CharacterBody2D.")

# --- LÓGICA DE MOVIMENTO ---

func calculate_walk_velocity(walk_direction: float, is_running: bool, profile: LocomotionProfile):
	if not profile:
		push_warning("MovementComponent recebeu um LocomotionProfile nulo.")
		return

	var target_speed = profile.speed
	if is_running:
		target_speed = profile.run_speed
		
	if walk_direction:
		owner_node.velocity.x = walk_direction * target_speed
	else:
		owner_node.velocity.x = move_toward(owner_node.velocity.x, 0, profile.speed)

# ESTA É A FUNÇÃO QUE FALTAVA
func apply_dodge_velocity(direction: Vector2, profile: DodgeProfile):
	if not profile:
		push_warning("MovementComponent recebeu um DodgeProfile nulo.")
		return
	
	# Resetamos a velocidade para garantir um dash limpo e consistente.
	owner_node.velocity = Vector2.ZERO

	if direction != Vector2.ZERO:
		# Aplicamos a velocidade do perfil na direção normalizada da esquiva.
		# Isto funciona para qualquer direção (vertical, horizontal ou diagonal).
		owner_node.velocity = direction.normalized() * profile.speed

func apply_gravity(delta: float):
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	if not owner_node.is_on_floor():
		owner_node.velocity.y += gravity * delta
