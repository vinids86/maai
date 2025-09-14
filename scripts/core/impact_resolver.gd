extends Node

class ContactResult extends Resource:
	enum Outcome {
		HIT,
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
	var attacker = hitbox.owner_actor
	var defender = hurtbox.owner_actor
	var attack_profile = hitbox.attack_profile
	
	if not attacker or not defender or not attack_profile:
		push_warning("ImpactResolver: Contexto de combate incompleto.")
		return

	var defender_sm = defender.find_child("StateMachine")
	var attacker_sm = attacker.find_child("StateMachine")
		
	var result = ContactResult.new()
	result.attacker_node = attacker
	result.defender_node = defender
	result.attack_profile = attack_profile
		
	if defender_sm and defender_sm.current_state.allow_autoblock():
		var defender_stamina = defender.find_child("StaminaComponent")
		if defender_stamina and defender_stamina.take_stamina_damage(attack_profile.stamina_damage):
			result.outcome = ContactResult.Outcome.BLOCKED
		else:
			result.outcome = ContactResult.Outcome.GUARD_BROKEN
	else:
		var defender_health = defender.find_child("HealthComponent")
		if defender_health is HealthComponent:
			defender_health.take_damage(attack_profile.damage)
		result.outcome = ContactResult.Outcome.HIT

	if defender_sm:
		defender_sm.on_impact_resolved(result)
	if attacker_sm:
		attacker_sm.on_impact_resolved(result)

	if defender.has_method("flash_red"):
		defender.flash_red()
