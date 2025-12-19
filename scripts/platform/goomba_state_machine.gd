class_name GoombaStateMachine
extends BaseSimpleStateMachine

# Implementação da lógica de decisão específica do Goomba
func _decide_next_state(reason: Dictionary):
	var outcome = reason.get("outcome")
	
	# 1. Prioridade: Se o ataque conectou (Recoil)
	# Isso deve acontecer antes de processar HIT para evitar cancelar o recuo
	if outcome == "ATTACK_CONNECTED":
		transition_to("SimpleRecoilState", reason)
		return
	
	# 2. Prioridade: Se tomou dano (Stagger)
	if outcome == "HIT":
		var knockback = reason.get("knockback_vector", Vector2.ZERO)
		transition_to("SimpleStaggerState", {"knockback_vector": knockback})
		return

	# 3. Fallback: Volta para o estado inicial (Patrulha)
	if states.has(initial_state_key):
		transition_to(initial_state_key)
