class_name GuardBrokenState
extends State

@export var guard_broken_profile: GuardBrokenProfile

var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	if not guard_broken_profile:
		push_warning("GuardBrokenState: Nenhum GuardBrokenProfile foi atribuído. A abortar.")
		state_machine.on_current_state_finished()
		return

	time_left_in_phase = guard_broken_profile.duration
	owner_node.velocity = Vector2.ZERO
	_emit_phase_signal()


func process_physics(delta: float, walk_direction: float, is_running: bool):
	if not guard_broken_profile:
		return

	time_left_in_phase -= delta
	if time_left_in_phase <= 0:
		state_machine.on_current_state_finished()


func _emit_phase_signal():
	var phase_data = {
		"state_name": self.name,
		"phase_name": "GUARD_BROKEN",
		"profile": guard_broken_profile,
		"animation_to_play": guard_broken_profile.animation_name,
		"sfx_to_play": guard_broken_profile.enter_sfx
	}
	state_machine.emit_phase_change(phase_data)
