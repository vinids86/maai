class_name DodgeState
extends State

var current_profile: DodgeProfile

enum Phases { ACTIVE, RECOVERY }
var current_phase: Phases
var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	owner_node.facing_locked = true
	
	self.current_profile = args.get("profile")
	var direction_vector = args.get("direction", Vector2.ZERO)

	if not current_profile:
		state_machine.on_current_state_finished()
		return
		
	movement_component.apply_dodge_velocity(direction_vector, current_profile)
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
	if current_phase == Phases.ACTIVE:
		var result_for_attacker = ContactResult.new()
		result_for_attacker.attacker_node = context.attacker_node
		result_for_attacker.defender_node = context.defender_node
		result_for_attacker.attack_profile = context.attack_profile
		result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.DODGED
		result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.NONE
		return result_for_attacker
	
	if current_phase == Phases.RECOVERY:
		return _handle_default_hit(context)
		
	return null

func _handle_default_hit(context: ContactContext) -> ContactResult:
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
	
	var result = ContactResult.new()
	result.attacker_node = context.attacker_node
	result.defender_node = context.defender_node
	result.attack_profile = context.attack_profile
	if was_poise_broken:
		result.defender_outcome = ContactResult.DefenderOutcome.POISE_BROKEN
	else:
		result.defender_outcome = ContactResult.DefenderOutcome.HIT
	result.attacker_outcome = ContactResult.AttackerOutcome.NONE
	return result

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
