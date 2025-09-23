class_name BlockStunState
extends State

var current_profile: BlockStunProfile

var time_left_in_phase: float = 0.0
var _recoil_velocity: Vector2

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")

	if not current_profile:
		state_machine.on_current_state_finished()
		return
	
	time_left_in_phase = current_profile.duration
	
	var recoil: Vector2 = args.get("knockback_vector", Vector2.ZERO)
	_recoil_velocity = recoil
	if recoil.x != 0:
		_recoil_velocity.x *= -owner_node.facing_sign
	
	_emit_phase_signal()

func process_physics(delta: float, _walk_direction: float, _is_running: bool):
	if not current_profile:
		return

	time_left_in_phase -= delta
	if time_left_in_phase <= 0:
		owner_node.velocity = Vector2.ZERO
		state_machine.on_current_state_finished()
		return
		
	if not owner_node.is_on_floor():
		var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
		_recoil_velocity.y += gravity * delta
	
	_recoil_velocity = _recoil_velocity.lerp(Vector2.ZERO, 0.15)
	owner_node.velocity = _recoil_velocity
	
	owner_node.move_and_slide()

func resolve_contact(context: ContactContext) -> ContactResult:
	var result_for_attacker = ContactResult.new()
	result_for_attacker.attacker_node = context.attacker_node
	result_for_attacker.defender_node = context.defender_node
	result_for_attacker.attack_profile = context.attack_profile

	var defender_shield_poise = context.defender_poise_comp.get_effective_shield_poise()
	var auto_block_succeeds = context.attacker_offensive_poise < defender_shield_poise

	if auto_block_succeeds:
		if context.defender_stamina_comp.take_stamina_damage(context.attack_profile.stamina_damage):
			var block_recoil_fraction: float = 0.2
			var base_knockback: Vector2 = context.attack_profile.knockback_vector
			var recoil_velocity: Vector2 = base_knockback * block_recoil_fraction
			
			var reason = { "outcome": "BLOCKED", "knockback_vector": recoil_velocity }
			state_machine.on_current_state_finished(reason)
			
			result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.BLOCKED
			result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.NONE
		else:
			var reason = { "outcome": "GUARD_BROKEN", "knockback_vector": context.attack_profile.knockback_vector }
			state_machine.on_current_state_finished(reason)
			result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.GUARD_BROKEN
			result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.GUARD_BREAK_SUCCESS
	else:
		context.defender_health_comp.take_damage(context.attack_profile.damage)
		
		var reason = { "outcome": "POISE_BROKEN", "knockback_vector": context.attack_profile.knockback_vector }
		state_machine.on_current_state_finished(reason)

		result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.POISE_BROKEN
		result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.NONE
	
	return result_for_attacker

func get_poise_shield_contribution() -> float:
	if not current_profile:
		return 0.0
	return current_profile.poise_shield_contribution

func allow_reentry() -> bool:
	return true

func _emit_phase_signal():
	var phase_data = {
		"state_name": self.name,
		"phase_name": "BLOCK_STUN",
		"profile": current_profile,
		"animation_to_play": current_profile.animation_name,
		"sfx_to_play": current_profile.sfx
	}
	state_machine.emit_phase_change(phase_data)
