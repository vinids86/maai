extends Node

signal impact_resolved(result: ContactResult)

class ContactResult extends Resource:
	enum Outcome {
		HIT,
		POISE_BROKEN,
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
		return

	var defender_sm = defender.find_child("StateMachine")
	
	var result = ContactResult.new()
	result.attacker_node = attacker
	result.defender_node = defender
	result.attack_profile = attack_profile
	
	var defender_poise_comp = defender.find_child("PoiseComponent")
	var was_poise_broken = false
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
