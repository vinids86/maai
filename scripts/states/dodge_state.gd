class_name DodgeState
extends State

var current_profile: DodgeProfile
var _current_direction: Vector2

enum Phases { ACTIVE, RECOVERY }
var current_phase: Phases
var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	owner_node.facing_locked = true
	
	self.current_profile = args.get("profile")
	self._current_direction = args.get("direction", Vector2.ZERO)

	if not current_profile:
		state_machine.on_current_state_finished()
		return
		
	movement_component.apply_dodge_velocity(_current_direction, current_profile)
	_change_phase(Phases.ACTIVE)

func exit():
	owner_node.facing_locked = false

func process_physics(delta: float, _walk_direction: float, _is_running: bool):
	if not current_profile:
		return

	time_left_in_phase -= delta
	
	while time_left_in_phase <= 0:
		var time_exceeded = -time_left_in_phase
		
		match current_phase:
			Phases.ACTIVE:
				_change_phase(Phases.RECOVERY)
				time_left_in_phase -= time_exceeded
			Phases.RECOVERY:
				state_machine.on_current_state_finished()
				return

	if not current_profile.ignores_gravity:
		movement_component.apply_gravity(delta)
		
func resolve_contact(context: ContactContext) -> ContactResult:
	var result_for_attacker = ContactResult.new()
	result_for_attacker.attacker_node = context.attacker_node
	result_for_attacker.defender_node = context.defender_node
	result_for_attacker.attack_profile = context.attack_profile
	
	if current_phase == Phases.ACTIVE:
		var is_thrust = context.attack_profile.unparryable_type == AttackProfile.UnparryableType.THRUST
		var is_forward_dodge = _current_direction.x * owner_node.facing_sign > 0

		if is_thrust:
			if is_forward_dodge:
				state_machine.on_current_state_finished({"outcome": "COUNTER_SUCCESS", "context": context})
				result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.COUNTER_SUCCESS
				result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.COUNTERED
			else:
				context.defender_health_comp.take_damage(context.attack_profile.damage)
				var reason = { "outcome": "POISE_BROKEN", "knockback_vector": context.attack_profile.knockback_vector }
				state_machine.on_current_state_finished(reason)
				result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.POISE_BROKEN
				result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.NONE
		else:
			result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.DODGED
			result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.NONE
		
		return result_for_attacker
	
	if current_phase == Phases.RECOVERY:
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
		
	return null

func get_poise_shield_contribution() -> float:
	if not current_profile:
		return 0.0
	return current_profile.poise_shield_contribution

func get_poise_impact_contribution() -> float:
	return 0.0

func _change_phase(new_phase: Phases):
	current_phase = new_phase
	
	var sfx_to_play: AudioStream
	match current_phase:
		Phases.ACTIVE:
			time_left_in_phase = current_profile.active_duration
			sfx_to_play = current_profile.active_sfx
		Phases.RECOVERY:
			time_left_in_phase = current_profile.recovery_duration
			sfx_to_play = current_profile.recovery_sfx
	
	var phase_data = {
		"state_name": self.name,
		"phase_name": Phases.keys()[current_phase],
		"profile": current_profile,
		"animation_to_play": current_profile.animation_name,
		"sfx_to_play": sfx_to_play
	}
	state_machine.emit_phase_change(phase_data)
