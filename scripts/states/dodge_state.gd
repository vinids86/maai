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

	if path_follower_component and owner_node.path_target:
		path_follower_component.start_following(owner_node.path_target)
		
	_change_phase(Phases.ACTIVE)

func exit():
	owner_node.facing_locked = false

	if path_follower_component:
		path_follower_component.stop_following()

	if owner_node.path_target:
		owner_node.path_target.position = Vector2.ZERO

func process_physics(delta: float, _walk_direction: float, _is_running: bool) -> Vector2:
	if not current_profile:
		return Vector2.ZERO

	var calculated_velocity = Vector2.ZERO
	if path_follower_component:
		calculated_velocity = path_follower_component.calculate_target_velocity(delta)

	time_left_in_phase -= delta
	
	while time_left_in_phase <= 0:
		var time_exceeded = -time_left_in_phase
		
		match current_phase:
			Phases.ACTIVE:
				_change_phase(Phases.RECOVERY)
				time_left_in_phase -= time_exceeded
			Phases.RECOVERY:
				state_machine.on_current_state_finished()
				return Vector2.ZERO
	
	return calculated_velocity
		
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
		return _resolve_default_contact(context)
		
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
