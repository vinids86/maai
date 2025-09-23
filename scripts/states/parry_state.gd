class_name ParryState
extends State

const ATTACKER_KNOCKBACK_ON_SUCCESS = Vector2(50, 0)

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
	owner_node.velocity = Vector2.ZERO
	_change_phase(Phases.ACTIVE)

func exit():
	owner_node.facing_locked = false

func process_physics(delta: float, _walk_direction: float, _is_running: bool):
	if not current_profile:
		return

	time_left_in_phase -= delta
	
	if time_left_in_phase <= 0:
		var time_exceeded = -time_left_in_phase
		
		match current_phase:
			Phases.ACTIVE:
				_change_phase(Phases.RECOVERY)
				time_left_in_phase -= time_exceeded
			Phases.SUCCESS:
				_change_phase(Phases.RECOVERY)
				time_left_in_phase -= time_exceeded
			Phases.RECOVERY:
				state_machine.on_current_state_finished()
				return

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

func _handle_default_hit(context: ContactContext) -> ContactResult:
	var result = ContactResult.new()
	result.attacker_node = context.attacker_node
	result.defender_node = context.defender_node
	result.attack_profile = context.attack_profile
	
	var attack_profile = context.attack_profile
	var was_poise_broken = false
	if context.defender_poise_comp and attack_profile.poise_damage >= context.defender_poise_comp.get_effective_poise():
		was_poise_broken = true
	
	context.defender_health_comp.take_damage(attack_profile.damage)
	
	var outcome = "HIT"
	if was_poise_broken:
		outcome = "POISE_BROKEN"
	
	var reason = {"outcome": outcome, "knockback_vector": attack_profile.knockback_vector}
	state_machine.on_current_state_finished(reason)
	
	result.attacker_outcome = ContactResult.AttackerOutcome.NONE
	result.defender_outcome = was_poise_broken and ContactResult.DefenderOutcome.POISE_BROKEN or ContactResult.DefenderOutcome.HIT
	return result

func resolve_contact(context: ContactContext) -> ContactResult:
	var result_for_attacker = ContactResult.new()
	result_for_attacker.attacker_node = context.attacker_node
	result_for_attacker.defender_node = context.defender_node
	result_for_attacker.attack_profile = context.attack_profile
	
	match current_phase:
		Phases.ACTIVE:
			var attack_profile = context.attack_profile
			
			if attack_profile.parry_interaction == AttackProfile.ParryInteractionType.UNPARRYABLE:
				return _handle_default_hit(context)
			
			_change_phase(Phases.SUCCESS)
			result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.PARRY_SUCCESS
			
			if context.defender_poise_comp and current_profile:
				context.defender_poise_comp.apply_poise_bonus(
					current_profile.poise_bonus_on_success,
					current_profile.poise_bonus_duration
				)

			var attacker_poise = attack_profile.action_poise
			var defender_effective_poise = context.defender_poise_comp.get_effective_poise()
			
			if defender_effective_poise >= attacker_poise:
				result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.PARRIED
				result_for_attacker.knockback_vector = ATTACKER_KNOCKBACK_ON_SUCCESS
			else:
				result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.DEFLECTED
				
			return result_for_attacker

		Phases.SUCCESS:
			return _handle_default_hit(context)

		Phases.RECOVERY:
			var block_recoil_fraction: float = 0.2
			var attack_knockback = context.attack_profile.knockback_vector
			
			if context.defender_stamina_comp.take_stamina_damage(context.attack_profile.stamina_damage):
				var recoil_velocity = attack_knockback * block_recoil_fraction
				var reason = {"outcome": "BLOCKED", "knockback_vector": recoil_velocity}
				state_machine.on_current_state_finished(reason)

				result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.NONE
				result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.BLOCKED
			else:
				var reason = {"outcome": "GUARD_BROKEN", "knockback_vector": attack_knockback}
				state_machine.on_current_state_finished(reason)
				result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.GUARD_BREAK_SUCCESS
				result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.GUARD_BROKEN
			return result_for_attacker
			
	return null

func allow_attack() -> bool:
	return false

func allow_reentry() -> bool:
	return true

func can_buffer_attack() -> bool:
	return current_phase == Phases.SUCCESS or current_phase == Phases.RECOVERY

func allow_autoblock() -> bool:
	return current_phase == Phases.RECOVERY
