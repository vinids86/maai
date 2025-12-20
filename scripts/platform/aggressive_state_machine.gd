class_name AggressiveStateMachine
extends BaseSimpleStateMachine

@export_group("Aggro Settings")
@export var detection_range: float = 300.0
@export var attack_range: float = 60.0
@export var attack_cooldown: float = 1.0

@export_group("State Map")
## Nome do nó de Perseguição (Padrão: SimpleChaseState, Voador: FlyingChaseState)
@export var chase_state_name: String = "SimpleChaseState"
## Nome do nó de Ataque (Padrão: SimpleAttackState, Voador: FlyingAttackState)
@export var attack_state_name: String = "SimpleAttackState"
## Nome do nó de Recuo
@export var recoil_state_name: String = "SimpleRecoilState"
## Nome do nó de Stagger (Dano)
@export var stagger_state_name: String = "SimpleStaggerState"

@export_group("Resistance Settings")
@export var immune_to_stagger: bool = false

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
			transition_to(chase_state_name)

func _decide_next_state(reason: Dictionary):
	var outcome = reason.get("outcome")
	
	# 1. Prioridade: Reação a Dano (Recoil/Stagger)
	if outcome == "ATTACK_CONNECTED":
		transition_to(recoil_state_name, reason)
		return
	
	if outcome == "HIT":
		if not immune_to_stagger or _groggy_timer > 0:
			var knockback = reason.get("knockback_vector", Vector2.ZERO)
			transition_to(stagger_state_name, {"knockback_vector": knockback})
		return

	# 2. Prioridade: Ciclo de Combate
	if outcome == "CHASE_FINISHED":
		if _cooldown_timer <= 0:
			transition_to(attack_state_name)
		else:
			transition_to(chase_state_name)
		return
		
	if outcome == "ATTACK_FINISHED":
		_cooldown_timer = attack_cooldown
		transition_to(chase_state_name)
		return

	# 3. Fallback: Perdeu o alvo ou terminou reação
	if outcome == "LOST_TARGET":
		if states.has(initial_state_key):
			transition_to(initial_state_key)
		return
		
	if outcome == "PARRY_RECOVERED":
		var dist_to_player = 9999.0
		if is_instance_valid(GameManager.player_node):
			dist_to_player = owner_node.global_position.distance_to(GameManager.player_node.global_position)
		
		if dist_to_player <= attack_range and _cooldown_timer <= 0:
			transition_to(attack_state_name)
		else:
			transition_to(chase_state_name)
		return

	var player = GameManager.player_node
	if is_instance_valid(player):
		var dist = owner_node.global_position.distance_to(player.global_position)
		if dist <= detection_range:
			transition_to(chase_state_name)
			return

	if states.has(initial_state_key):
		transition_to(initial_state_key)
