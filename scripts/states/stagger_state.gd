class_name StaggerState
extends State

var current_profile: StaggerProfile

var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")

	if not current_profile:
		push_warning("StaggerState: Não recebeu um StaggerProfile. A abortar.")
		state_machine.on_current_state_finished()
		return

	time_left_in_phase = current_profile.duration
	
	var knockback: Vector2 = args.get("knockback_vector", Vector2.ZERO)
	owner_node.velocity = knockback
	if knockback.x != 0:
		owner_node.velocity.x *= -owner_node.facing_sign

	var phase_data := {
		"state_name": self.name,
		"phase_name": "STUN",
		"profile": current_profile,
		"sfx_to_play": current_profile.enter_sfx,
		"animation_to_play": current_profile.animation_name
	}
	state_machine.emit_phase_change(phase_data)


func process_physics(delta: float, walk_direction: float, is_running: bool):
	if not current_profile:
		return

	time_left_in_phase -= delta
	if time_left_in_phase <= 0.0:
		state_machine.on_current_state_finished()


func can_initiate_attack() -> bool:
	return false

func can_buffer_attack() -> bool:
	return true

func allow_autoblock() -> bool:
	return false
