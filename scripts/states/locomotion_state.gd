class_name LocomotionState
extends State

@export var locomotion_profile: LocomotionProfile

# Guardamos o valor da gravidade para fácil acesso.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# A responsabilidade deste estado é gerir o movimento contínuo.
func process_physics(delta: float):
	# --- GRAVIDADE ---
	# Esta secção garante que o personagem é afetado pela gravidade.
	if not owner_node.is_on_floor():
		owner_node.velocity.y += gravity * delta

	# --- MOVIMENTO HORIZONTAL ---
	if not locomotion_profile:
		push_warning("LocomotionState não tem um LocomotionProfile atribuído no Inspetor.")
		return

	# Lemos os inputs de eixo a cada frame para um movimento suave.
	var walk_direction = Input.get_axis("move_left", "move_right")
	var is_running = Input.is_action_pressed("run")
	
	movement_component.calculate_walk_velocity(walk_direction, is_running, locomotion_profile)


# Esta função permanece vazia, pois o Player trata dos inputs de ação discretos.
func process_input(event: InputEvent):
	pass


# --- FUNÇÕES DE PERMISSÃO ---

# ESTA É A FUNÇÃO CORRIGIDA
# Agora, este estado só permite que o jogador inicie uma esquiva se o personagem estiver no chão.
func allow_dodge() -> bool:
	return owner_node.is_on_floor()
