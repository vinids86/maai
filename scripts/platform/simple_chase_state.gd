class_name SimpleChaseState
extends SimpleState

# Referência para ler configurações de range
var _aggressive_sm: AggressiveStateMachine

func enter(_args: Dictionary = {}):
	_aggressive_sm = state_machine as AggressiveStateMachine
	
	# Envia sinal para feedback visual (animação de corrida)
	state_machine.emit_phase_change({
		"state": "SimpleChaseState",
		"phase": "chase",
		"animation_to_play": "run"
	})

func process_physics(delta: float) -> Vector2:
	var player = GameManager.player_node
	
	# Validação de segurança: se não há SM ou Player, desiste
	if not is_instance_valid(player) or not _aggressive_sm:
		state_machine.on_current_state_finished({"outcome": "LOST_TARGET"})
		return Vector2.ZERO
		
	var to_player = player.global_position - owner_node.global_position
	var dist = to_player.length()
	
	# Condição de Saída 1: Chegou no range de ataque
	if dist <= _aggressive_sm.attack_range:
		state_machine.on_current_state_finished({"outcome": "CHASE_FINISHED"})
		return Vector2.ZERO
		
	# Condição de Saída 2: Jogador se afastou demais (Histerese de 1.5x o range de detecção)
	if dist > _aggressive_sm.detection_range * 1.5:
		state_machine.on_current_state_finished({"outcome": "LOST_TARGET"})
		return Vector2.ZERO
	
	# Lógica de Movimento
	var direction = sign(to_player.x)
	if direction != 0:
		_flip_owner(direction)
		
	var speed = 0.0
	# Tenta obter velocidade de corrida do perfil de locomoção, se existir
	if owner_node.has_method("get_locomotion_profile"):
		var profile = owner_node.get_locomotion_profile()
		if profile:
			speed = profile.run_speed
	
	# Fallback simples se não houver profile (opcional, baseado na implementação do SimpleEnemy)
	if speed == 0.0:
		speed = 100.0 
			
	var velocity_x = direction * speed
	var velocity_y = owner_node.velocity.y
	
	# Aplica gravidade se estiver no ar
	if not owner_node.is_on_floor():
		velocity_y += 980.0 * delta
		
	return Vector2(velocity_x, velocity_y)

func _flip_owner(dir_sign: float):
	if owner_node.has_method("set_facing_direction"):
		owner_node.set_facing_direction(dir_sign)
