class_name LocomotionState
extends State

@export var locomotion_profile: LocomotionProfile

# Guardamos o valor da gravidade para fácil acesso.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# A função agora recebe o estado de corrida do Player.
func process_physics(delta: float, is_running: bool = false):
	# --- GRAVIDADE ---
	if not owner_node.is_on_floor():
		owner_node.velocity.y += gravity * delta

	# --- MOVIMENTO HORIZONTAL ---
	if not locomotion_profile:
		push_warning("LocomotionState não tem um LocomotionProfile atribuído no Inspetor.")
		return

	# Lemos os inputs de eixo a cada frame para um movimento suave.
	var walk_direction = Input.get_axis("move_left", "move_right")
	
	# A lógica de corrida agora usa o parâmetro, em vez de verificar o input diretamente.
	movement_component.calculate_walk_velocity(walk_direction, is_running, locomotion_profile)


func process_input(event: InputEvent):
	pass

# --- FUNÇÕES DE PERMISSÃO ---

func allow_dodge() -> bool:
	return owner_node.is_on_floor()
