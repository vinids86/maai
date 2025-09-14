class_name BlockStunState
extends State

@export var block_stun_profile: BlockStunProfile

var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	if not block_stun_profile:
		push_warning("BlockStunState: Nenhum BlockStunProfile foi atribuído. A abortar.")
		state_machine.on_current_state_finished()
		return
	
	time_left_in_phase = block_stun_profile.duration
	owner_node.velocity = Vector2.ZERO
	_emit_phase_signal()


func process_physics(delta: float, walk_direction: float, is_running: bool):
	if not block_stun_profile:
		return

	time_left_in_phase -= delta
	if time_left_in_phase <= 0:
		state_machine.on_current_state_finished()


func _emit_phase_signal():
	var phase_data = {
		"state_name": self.name,
		"phase_name": "BLOCK_STUN",
		"profile": block_stun_profile,
		"animation_to_play": block_stun_profile.animation_name,
		"sfx_to_play": block_stun_profile.sfx
	}
	state_machine.emit_phase_change(phase_data)
