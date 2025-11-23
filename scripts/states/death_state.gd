class_name DeathState
extends State

var current_profile: DeathProfile

func enter(args: Dictionary = {}):
	current_profile = args.get("profile")
	
	# --- LÓGICA DE CADÁVER ---
	# 1. Remove colisão com Player/Inimigos (Layer 0 geralmente é vazia ou ajustada)
	owner_node.collision_layer = 0
	# 2. Mantém colisão apenas com o Mundo (Layer 1) para cair no chão
	owner_node.collision_mask = 1 
	# -------------------------

	# Garante que o corpo pare horizontalmente
	owner_node.velocity.x = 0 
	
	# Restaura a chamada correta para disparar animação e som
	_emit_phase_signal()

func process_physics(delta: float, _walk_direction: float, _is_running: bool) -> Vector2:
	var new_velocity = owner_node.velocity
	
	# Aplica gravidade para cair se morrer no ar
	new_velocity = physics_component.apply_gravity(new_velocity, delta)
	
	# Aplica fricção forte para parar de deslizar no chão
	new_velocity.x = move_toward(new_velocity.x, 0, 2000.0 * delta)
	
	return new_velocity

# --- MÉTODO RESTAURADO ---
func _emit_phase_signal():
	if not current_profile:
		return
	
	# Empacota os dados conforme o padrão do seu projeto (AirborneState, etc)
	var phase_data = {
		"state_name": self.name,
		# "phase_name": Não aplicável para morte única, mas pode ser útil se houver fases
		"animation_to_play": current_profile.animation_name,
		"sfx_to_play": current_profile.sfx # Agora o AudioComponent vai receber isso!
	}
	
	state_machine.emit_phase_change(phase_data)

# --- BLOQUEIO DE INPUTS (MANTIDO) ---
func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_jump_input(_profile: JumpProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dash_input(_profile: DashProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_sequence_skill_input(_skill_attack_set: AttackSet) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func get_poise_shield_contribution() -> float:
	return 0.0
