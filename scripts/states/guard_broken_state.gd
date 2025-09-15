class_name GuardBrokenState
extends State

var current_profile: GuardBrokenProfile

var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")

	if not current_profile:
		push_warning("GuardBrokenState: Não recebeu um GuardBrokenProfile. A abortar.")
		state_machine.on_current_state_finished()
		return

	time_left_in_phase = current_profile.duration
	owner_node.velocity = Vector2.ZERO
	_emit_phase_signal()


func process_physics(delta: float, walk_direction: float, is_running: bool):
	if not current_profile:
		return

	time_left_in_phase -= delta
	if time_left_in_phase <= 0:
		state_machine.on_current_state_finished()


func _emit_phase_signal():
	var phase_data = {
		"state_name": self.name,
		"phase_name": "GUARD_BROKEN",
		"profile": current_profile,
		"animation_to_play": current_profile.animation_name,
		"sfx_to_play": current_profile.enter_sfx
	}
	state_machine.emit_phase_change(phase_data)
