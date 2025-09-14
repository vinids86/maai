extends Node

signal impact_resolved(result: ContactResult)

class ContactResult extends Resource:
	enum Outcome {
		HIT,
		POISE_BROKEN,
		PARRY_SUCCESS,
		PARRIED,
		BLOCKED,
		GUARD_BROKEN,
		DODGED
	}
	var outcome: Outcome
	var attacker_node: Node
	var defender_node: Node
	var attack_profile: AttackProfile

func resolve_contact(hitbox: Hitbox, hurtbox: Hurtbox):
	var attacker: Node = hitbox.owner_actor
	var defender: Node = hurtbox.owner_actor
	var attack_profile: AttackProfile = hitbox.attack_profile
	
	if not attacker or not defender or not attack_profile:
		return

	var defender_sm: StateMachine = defender.find_child("StateMachine") as StateMachine
	
	var result: ContactResult = ContactResult.new()
	result.attacker_node = attacker
	result.defender_node = defender
	result.attack_profile = attack_profile

	# >>> Inserção mínima: aviso SINCRÔNICO para IA tentar parry no mesmo frame <<<
	var defender_ai: AIController = defender.find_child("AIController") as AIController
	if defender_ai != null:
		defender_ai.on_incoming_attack(attacker as CharacterBody2D, hitbox)
	# <<< fim da inserção >>>
	
	if defender_sm and defender_sm.current_state is ParryState:
		if (defender_sm.current_state as ParryState).is_in_active_phase():
			result.outcome = ContactResult.Outcome.PARRY_SUCCESS
			emit_signal("impact_resolved", result)
			
			var parried_result: ContactResult = result.duplicate()
			parried_result.outcome = ContactResult.Outcome.PARRIED
			emit_signal("impact_resolved", parried_result)
			return

	var defender_poise_comp = defender.find_child("PoiseComponent")
	var was_poise_broken: bool = false
	if defender_poise_comp:
		var defender_poise = defender_poise_comp.get_effective_poise()
		if attack_profile.poise_damage >= defender_poise:
			was_poise_broken = true

	if defender_sm and defender_sm.current_state.allow_autoblock():
		var defender_stamina = defender.find_child("StaminaComponent")
		if defender_stamina and defender_stamina.take_stamina_damage(attack_profile.stamina_damage):
			result.outcome = ContactResult.Outcome.BLOCKED
		else:
			result.outcome = ContactResult.Outcome.GUARD_BROKEN
	elif was_poise_broken:
		result.outcome = ContactResult.Outcome.POISE_BROKEN
	else:
		result.outcome = ContactResult.Outcome.HIT
	
	if result.outcome != ContactResult.Outcome.BLOCKED:
		var defender_health = defender.find_child("HealthComponent")
		if defender_health is HealthComponent:
			defender_health.take_damage(attack_profile.damage)
	
	emit_signal("impact_resolved", result)

	if defender.has_method("flash_red"):
		defender.flash_red()
