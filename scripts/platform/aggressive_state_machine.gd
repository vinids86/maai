class_name AggressiveStateMachine
extends BaseSimpleStateMachine

@export_group("Aggro Settings")
@export var detection_range: float = 300.0
@export var attack_range: float = 60.0
@export var attack_cooldown: float = 1.0

var _cooldown_timer: float = 0.0

func process_physics(delta: float) -> Vector2:
	if _cooldown_timer > 0:
		_cooldown_timer -= delta

	# Lógica de detecção automática se estiver patrulhando
	if current_state and current_state.name == initial_state_key:
		_check_for_player()

	return super.process_physics(delta)

func _check_for_player() -> void:
	var player = GameManager.player_node
	if is_instance_valid(player):
		var dist = owner_node.global_position.distance_to(player.global_position)
		if dist <= detection_range:
			transition_to("SimpleChaseState")

func _decide_next_state(reason: Dictionary):
	var outcome = reason.get("outcome")
	
	# 1. Prioridade: Reação a Dano (Recoil/Stagger)
	if outcome == "ATTACK_CONNECTED":
		transition_to("SimpleRecoilState", reason)
		return
	
	if outcome == "HIT":
		var knockback = reason.get("knockback_vector", Vector2.ZERO)
		transition_to("SimpleStaggerState", {"knockback_vector": knockback})
		return

	# 2. Prioridade: Ciclo de Combate
	if outcome == "CHASE_FINISHED":
		# Chegou no range. Pode atacar?
		if _cooldown_timer <= 0:
			transition_to("SimpleAttackState")
		else:
			# Se estiver em cooldown, continua perseguindo (ou poderia esperar)
			# Reiniciamos o ChaseState para ele continuar grudado no player
			transition_to("SimpleChaseState")
		return
		
	if outcome == "ATTACK_FINISHED":
		_cooldown_timer = attack_cooldown
		# Volta a perseguir imediatamente para manter pressão
		transition_to("SimpleChaseState")
		return

	# 3. Fallback: Perdeu o alvo ou terminou reação
	if outcome == "LOST_TARGET":
		if states.has(initial_state_key):
			transition_to(initial_state_key)
		return

	# Se terminou um Stagger/Recoil, voltamos a perseguir se o player estiver perto
	# senão voltamos para patrulha
	var player = GameManager.player_node
	if is_instance_valid(player):
		var dist = owner_node.global_position.distance_to(player.global_position)
		if dist <= detection_range:
			transition_to("SimpleChaseState")
			return

	if states.has(initial_state_key):
		transition_to(initial_state_key)
