extends Node

signal impact_resolved(result: ContactResult)

class ContactResult extends Resource:
	enum DefenderOutcome { HIT, POISE_BROKEN, PARRY_SUCCESS, BLOCKED, GUARD_BROKEN, DODGED }
	enum AttackerOutcome { NONE, PARRIED, GUARD_BREAK_SUCCESS }

	var attacker_node: Node
	var defender_node: Node
	var attack_profile: AttackProfile
	var knockback_vector: Vector2

	var defender_outcome: DefenderOutcome
	var attacker_outcome: AttackerOutcome = AttackerOutcome.NONE

func resolve_contact(hitbox: Hitbox, hurtbox: Hurtbox):
	var attacker: Node = hitbox.owner_actor
	var defender: Node = hurtbox.owner_actor
	var attack_profile: AttackProfile = hitbox.attack_profile

	if attacker == null or defender == null or attack_profile == null:
		return

	var defender_sm: StateMachine = defender.find_child("StateMachine") as StateMachine

	var result: ContactResult = ContactResult.new()
	result.attacker_node = attacker
	result.defender_node = defender
	result.attack_profile = attack_profile
	result.knockback_vector = attack_profile.knockback_vector

	var defender_ai: AIController = defender.find_child("AIController") as AIController
	if defender_ai != null:
		defender_ai.on_incoming_attack(attacker as CharacterBody2D, hitbox)

	if defender_sm != null and defender_sm.current_state is ParryState:
		var ps: ParryState = defender_sm.current_state as ParryState
		if ps.is_in_active_phase():
			result.defender_outcome = ContactResult.DefenderOutcome.PARRY_SUCCESS
			result.attacker_outcome = ContactResult.AttackerOutcome.PARRIED
			emit_signal("impact_resolved", result)
			return

	var was_poise_broken: bool = false
	var defender_poise_comp: Node = defender.find_child("PoiseComponent")
	if defender_poise_comp != null:
		var defender_poise: float = defender_poise_comp.get_effective_poise()
		if attack_profile.poise_damage >= defender_poise:
			was_poise_broken = true

	if defender_sm != null and defender_sm.current_state.allow_autoblock():
		var defender_stamina: StaminaComponent = defender.find_child("StaminaComponent") as StaminaComponent
		if defender_stamina != null and defender_stamina.take_stamina_damage(attack_profile.stamina_damage):
			result.defender_outcome = ContactResult.DefenderOutcome.BLOCKED
		else:
			result.defender_outcome = ContactResult.DefenderOutcome.GUARD_BROKEN
			result.attacker_outcome = ContactResult.AttackerOutcome.GUARD_BREAK_SUCCESS
	elif was_poise_broken:
		result.defender_outcome = ContactResult.DefenderOutcome.POISE_BROKEN
	else:
		result.defender_outcome = ContactResult.DefenderOutcome.HIT

	if result.defender_outcome != ContactResult.DefenderOutcome.BLOCKED:
		var defender_health: HealthComponent = defender.find_child("HealthComponent") as HealthComponent
		if defender_health is HealthComponent:
			defender_health.take_damage(attack_profile.damage)

	emit_signal("impact_resolved", result)

	if defender.has_method("flash_red"):
		defender.flash_red()
