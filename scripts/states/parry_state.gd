class_name ParryState
extends State

const ATTACKER_KNOCKBACK_ON_SUCCESS = Vector2(250, 0)

var current_profile: ParryProfile

enum Phases { ACTIVE, SUCCESS, RECOVERY }
var current_phase: Phases
var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")
	
	if not current_profile:
		state_machine.on_current_state_finished()
		return
	
	owner_node.facing_locked = true
	_change_phase(Phases.ACTIVE)

func exit():
	owner_node.facing_locked = false

func process_physics(delta: float, _walk_direction: float, _is_running: bool) -> Vector2:
	if not current_profile:
		return physics_component.apply_gravity(Vector2.ZERO, delta)

	time_left_in_phase -= delta
	
	if time_left_in_phase <= 0:
		var time_exceeded = -time_left_in_phase
		
		match current_phase:
			Phases.ACTIVE:
				_change_phase(Phases.RECOVERY)
				time_left_in_phase -= time_exceeded
			Phases.SUCCESS:
				state_machine.on_current_state_finished()
				return physics_component.apply_gravity(Vector2.ZERO, delta)
			Phases.RECOVERY:
				state_machine.on_current_state_finished()
				return physics_component.apply_gravity(Vector2.ZERO, delta)
				
	return physics_component.apply_gravity(Vector2.ZERO, delta)

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	if current_phase == Phases.SUCCESS:
		var riposte_profile = owner_node.get_riposte_profile()
		var context = {"override_profile": riposte_profile}
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED, context)
	
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	if current_phase == Phases.SUCCESS:
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
		
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	if current_phase == Phases.SUCCESS or current_phase == Phases.RECOVERY:
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
		
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func _change_phase(new_phase: Phases):
	current_phase = new_phase
	
	var sfx_to_play: AudioStream
	match current_phase:
		Phases.ACTIVE:
			time_left_in_phase = current_profile.active_duration
			sfx_to_play = current_profile.active_sfx
		Phases.SUCCESS:
			time_left_in_phase = current_profile.success_duration
			sfx_to_play = current_profile.success_sfx
		Phases.RECOVERY:
			time_left_in_phase = current_profile.recovery_duration
			sfx_to_play = current_profile.recovery_sfx
			
	var phase_data = {
		"state_name": self.name,
		"phase_name": Phases.keys()[current_phase],
		"profile": current_profile,
		"sfx_to_play": sfx_to_play
	}
	
	if current_phase == Phases.ACTIVE:
		phase_data["animation_to_play"] = current_profile.animation_name
	
	state_machine.emit_phase_change(phase_data)

func _handle_direct_hit(context: ContactContext) -> ContactResult:
	var result = ContactResult.new()
	result.attacker_node = context.attacker_node
	result.defender_node = context.defender_node
	result.attack_profile = context.attack_profile

	context.defender_health_comp.take_damage(context.attack_profile.damage)
	
	var reason = {"outcome": "POISE_BROKEN", "knockback_vector": context.attack_profile.knockback_vector}
	state_machine.on_current_state_finished(reason)
	
	result.attacker_outcome = ContactResult.AttackerOutcome.NONE
	result.defender_outcome = ContactResult.DefenderOutcome.POISE_BROKEN
	return result

func resolve_contact(context: ContactContext) -> ContactResult:
	var result_for_attacker = ContactResult.new()
	result_for_attacker.attacker_node = context.attacker_node
	result_for_attacker.defender_node = context.defender_node
	result_for_attacker.attack_profile = context.attack_profile
	
	match current_phase:
		Phases.ACTIVE:
			if context.attack_profile.parry_interaction == AttackProfile.ParryInteractionType.UNPARRYABLE:
				return _handle_direct_hit(context)
			
			_change_phase(Phases.SUCCESS)
			result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.PARRY_SUCCESS
			
			var focus_comp = owner_node.find_child("FocusComponent")
			if focus_comp:
				focus_comp.gain_focus(focus_comp.focus_gain_on_parry)
			
			if context.defender_poise_comp and current_profile:
				context.defender_poise_comp.apply_shield_bonus(
					current_profile.shield_bonus_on_success,
					current_profile.bonus_duration
				)
				context.defender_poise_comp.apply_sword_bonus(
					current_profile.sword_bonus_on_success,
					current_profile.bonus_duration
				)

			var defender_defensive_poise = context.defender_poise_comp.get_effective_shield_poise()
			
			if defender_defensive_poise >= context.attacker_offensive_poise:
				result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.PARRIED
				result_for_attacker.knockback_vector = ATTACKER_KNOCKBACK_ON_SUCCESS
			else:
				result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.DEFLECTED
				
			return result_for_attacker

		Phases.SUCCESS:
			return _handle_direct_hit(context)

		Phases.RECOVERY:
			return _resolve_default_contact(context)
			
	return null

func get_poise_shield_contribution() -> float:
	if not current_profile:
		return 0.0
	return current_profile.poise_shield_contribution

func get_poise_impact_contribution() -> float:
	return 0.0

func allow_reentry() -> bool:
	return true
