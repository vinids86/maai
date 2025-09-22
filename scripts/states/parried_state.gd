class_name ParriedState
extends State

var current_profile: ParriedProfile

var time_left_in_phase: float = 0.0
var _knockback_velocity: Vector2

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")
	
	if not current_profile:
		state_machine.on_current_state_finished()
		return

	time_left_in_phase = current_profile.duration
	
	var knockback: Vector2 = args.get("knockback_vector", Vector2.ZERO)
	_knockback_velocity = knockback
	if knockback.x != 0:
		_knockback_velocity.x *= -owner_node.facing_sign

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
		_knockback_velocity.y += gravity * delta
	
	_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, 0.1)
	owner_node.velocity = _knockback_velocity
		
	owner_node.move_and_slide()

func resolve_contact(context: ContactContext) -> ContactResult:
	return _handle_default_hit(context)

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

	var reason = {
		"outcome": outcome,
		"knockback_vector": context.attack_profile.knockback_vector
	}
	state_machine.on_current_state_finished(reason)
	
	result.attacker_outcome = ContactResult.AttackerOutcome.NONE
	if was_poise_broken:
		result.defender_outcome = ContactResult.DefenderOutcome.POISE_BROKEN
	else:
		result.defender_outcome = ContactResult.DefenderOutcome.HIT
		
	return result

func allow_reentry() -> bool:
	return true

func _emit_phase_signal():
	var phase_data = {
		"state_name": self.name,
		"phase_name": "STUNNED",
		"profile": current_profile,
		"animation_to_play": current_profile.animation_name,
		"sfx_to_play": current_profile.sfx
	}
	state_machine.emit_phase_change(phase_data)
