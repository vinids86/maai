class_name LocomotionState
extends State

var current_profile: LocomotionProfile

enum Phases { IDLE, WALK, RUN }
var current_phase: Phases = Phases.IDLE

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")
	if not current_profile:
		push_warning("LocomotionState: Não recebeu um LocomotionProfile. A abortar.")
		return
	
	_change_phase(Phases.IDLE)

func process_physics(delta: float, walk_direction: float, is_running: bool):
	if not owner_node.is_on_floor():
		owner_node.velocity.y += gravity * delta

	if not current_profile:
		return

	_update_facing_sign(walk_direction)
	
	movement_component.calculate_walk_velocity(walk_direction, is_running, current_profile)
	
	_update_and_emit_phase(walk_direction, is_running)

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	return InputHandlerResult.ACCEPTED

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	if owner_node.is_on_floor():
		return InputHandlerResult.ACCEPTED
	return InputHandlerResult.REJECTED
	
func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	return InputHandlerResult.ACCEPTED

func handle_sequence_skill_input(_skill_attack_set: AttackSet) -> InputHandlerResult:
	if owner_node.is_on_floor():
		return InputHandlerResult.ACCEPTED
	return InputHandlerResult.REJECTED

func resolve_contact(context: ContactContext) -> ContactResult:
	var result_for_attacker = ContactResult.new()
	result_for_attacker.attacker_node = context.attacker_node
	result_for_attacker.defender_node = context.defender_node
	result_for_attacker.attack_profile = context.attack_profile

	if context.attack_profile.parry_interaction == AttackProfile.ParryInteractionType.UNPARRYABLE:
		context.defender_health_comp.take_damage(context.attack_profile.damage)
		var reason = { "outcome": "POISE_BROKEN", "knockback_vector": context.attack_profile.knockback_vector }
		state_machine.on_current_state_finished(reason)
		result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.POISE_BROKEN
		result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.NONE
		return result_for_attacker

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

func _update_facing_sign(direction: float):
	if owner_node.facing_locked:
		return
		
	if direction > 0:
		owner_node.facing_sign = 1
	elif direction < 0:
		owner_node.facing_sign = -1

func _update_and_emit_phase(walk_direction: float, is_running: bool):
	var new_phase: Phases
	
	if walk_direction == 0:
		new_phase = Phases.IDLE
	elif is_running:
		new_phase = Phases.RUN
	else:
		new_phase = Phases.WALK
		
	if new_phase != current_phase:
		_change_phase(new_phase)

func _change_phase(new_phase: Phases):
	current_phase = new_phase
	
	var anim_to_play: StringName
	match current_phase:
		Phases.IDLE:
			anim_to_play = current_profile.idle_animation
		Phases.WALK:
			anim_to_play = current_profile.walk_animation
		Phases.RUN:
			anim_to_play = current_profile.run_animation
	
	var phase_data = {
		"state_name": self.name,
		"phase_name": Phases.keys()[current_phase],
		"profile": current_profile,
		"animation_to_play": anim_to_play
	}
	
	state_machine.emit_phase_change(phase_data)
