class_name DeathState
extends State

var current_profile: DeathProfile

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")
	if not current_profile:
		push_warning("DeathState: Não recebeu um DeathProfile.")
		# Mesmo sem perfil, a morte deve continuar.
	
	# 1. Toca a animação e o som de morte
	_emit_phase_signal()
	
	# 2. Remove a HUD (supondo que o owner tem esta função)
	if owner_node.has_method("hide_status_ui"):
		owner_node.hide_status_ui()
	
	# 3. Desativa todas as colisões físicas e de áreas (hurtboxes)
	# Isto torna o personagem um "fantasma"
	owner_node.set_collision_layer_value(1, false) # Ajuste o '1' para a sua camada de colisão principal
	owner_node.set_collision_mask_value(1, false)

	# Itera por todos os filhos para desativar hurtboxes ou outras áreas
	for child in owner_node.get_children():
		if child is CollisionShape2D:
			child.disabled = true
		if child is Area2D:
			child.monitoring = false
			child.monitorable = false
			
	# Garante que o personagem pare completamente
	owner_node.velocity = Vector2.ZERO

# --- Funções "vazias" para garantir que o personagem não faça mais nada ---

func process_physics(_delta: float, _walk_direction: float, _is_running: bool):
	pass # Nenhuma física é processada.

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func resolve_contact(_context: ContactContext) -> ContactResult:
	return null # Não reage a nenhum contato.

func _emit_phase_signal():
	var phase_data = {
		"state_name": self.name,
		"phase_name": "DIED",
		"profile": current_profile,
	}
	if current_profile:
		phase_data["animation_to_play"] = current_profile.animation_name
		phase_data["sfx_to_play"] = current_profile.sfx
	
	state_machine.emit_phase_change(phase_data)
