extends Node

signal impact_resolved(result: ContactResult)

func resolve_contact(hitbox: Hitbox, hurtbox: Hurtbox):
	var attacker: Node = hitbox.owner_actor
	var defender: Node = hurtbox.owner_actor

	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return

	var context = ContactContext.new()
	context.attacker_node = attacker
	context.defender_node = defender
	
	# Usa o source_node do hitbox (projétil ou o próprio atacante).
	if hitbox.source_node:
		context.source_node = hitbox.source_node
	else:
		context.source_node = attacker
		
	context.attack_profile = hitbox.attack_profile
	
	var attacker_poise_comp = attacker.find_child("PoiseComponent")
	if attacker_poise_comp:
		context.attacker_offensive_poise = attacker_poise_comp.get_effective_offensive_poise()
	else:
		context.attacker_offensive_poise = 0.0
	
	context.defender_health_comp = defender.find_child("HealthComponent")
	context.defender_stamina_comp = defender.find_child("StaminaComponent")
	context.defender_poise_comp = defender.find_child("PoiseComponent")
	
	var defender_sm = defender.find_child("StateMachine")
	if not defender_sm:
		defender_sm = defender.find_child("SimpleStateMachine")
	context.defender_state_machine = defender_sm

	if not (context.defender_health_comp and context.defender_state_machine):
		return

	var defender_ai_controller = defender.find_child("AIController")
	if defender_ai_controller:
		defender_ai_controller.on_incoming_attack(attacker, hitbox)

	var defender_current_state = context.defender_state_machine.current_state
	
	if defender_current_state.has_method("get_attack_profile"):
		context.defender_attack_profile = defender_current_state.get_attack_profile()

	# O Estado decide o resultado
	var result_for_attacker: ContactResult = defender_current_state.resolve_contact(context)

	if result_for_attacker:
		result_for_attacker.source_node = context.source_node
		if context.source_node and context.source_node.has_method("on_impact_confirmed"):
			context.source_node.on_impact_confirmed()
			
		emit_signal("impact_resolved", result_for_attacker)
