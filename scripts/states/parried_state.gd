class_name ParriedState
extends State

var current_profile: ParriedProfile

enum Phases { RECOIL, REACTIVE }
var _current_internal_phase: Phases

var time_left_in_phase: float = 0.0
var _knockback_velocity: Vector2

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")
	
	if not current_profile:
		state_machine.on_current_state_finished()
		return

	var knockback: Vector2 = args.get("knockback_vector", Vector2.ZERO)
	_knockback_velocity = knockback
	if knockback.x != 0:
		_knockback_velocity.x *= -owner_node.facing_sign

	var poise_comp = owner_node.find_child("PoiseComponent")
	if poise_comp:
		poise_comp.apply_shield_bonus(
			-current_profile.poise_shield_debuff, 
			current_profile.debuff_duration
		)
		poise_comp.apply_sword_bonus(
			-current_profile.poise_sword_debuff, 
			current_profile.debuff_duration
		)

	_change_phase(Phases.RECOIL)

func process_physics(delta: float, _walk_direction: float, _is_running: bool):
	if not current_profile:
		return

	time_left_in_phase -= delta

	while time_left_in_phase <= 0:
		var time_exceeded = -time_left_in_phase
		
		if _current_internal_phase == Phases.RECOIL:
			_change_phase(Phases.REACTIVE)
			time_left_in_phase -= time_exceeded
		else:
			owner_node.velocity = Vector2.ZERO
			state_machine.on_current_state_finished()
			return
	
	if not owner_node.is_on_floor():
		var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
		_knockback_velocity.y += gravity * delta
	
	_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, 0.1)
	owner_node.velocity = _knockback_velocity

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	if _current_internal_phase == Phases.REACTIVE:
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	if _current_internal_phase == Phases.REACTIVE:
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func resolve_contact(context: ContactContext) -> ContactResult:
	var result_for_attacker = ContactResult.new()
	result_for_attacker.attacker_node = context.attacker_node
	result_for_attacker.defender_node = context.defender_node
	result_for_attacker.attack_profile = context.attack_profile

	var defender_shield_poise = context.defender_poise_comp.get_effective_shield_poise()
	var auto_block_succeeds = context.attacker_offensive_poise < defender_shield_poise
	if auto_block_succeeds:
		if context.defender_stamina_comp.take_stamina_damage(context.attack_profile.stamina_damage):
			var block_recoil_fraction: float = 0.4
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

func _change_phase(new_phase: Phases):
	_current_internal_phase = new_phase
	
	var sfx_to_play: AudioStream
	match _current_internal_phase:
		Phases.RECOIL:
			time_left_in_phase = current_profile.recoil_duration
			sfx_to_play = current_profile.sfx
		Phases.REACTIVE:
			time_left_in_phase = current_profile.reactive_duration
	
	var phase_data = {
		"state_name": self.name,
		"phase_name": Phases.keys()[_current_internal_phase],
		"profile": current_profile,
		"sfx_to_play": sfx_to_play
	}

	if _current_internal_phase == Phases.RECOIL:
		phase_data["animation_to_play"] = current_profile.animation_name
	
	state_machine.emit_phase_change(phase_data)
