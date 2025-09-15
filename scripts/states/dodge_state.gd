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
		push_warning("DodgeState: Não recebeu um DodgeProfile para executar. A abortar.")
		state_machine.on_current_state_finished()
		return
		
	movement_component.apply_dodge_velocity(direction_vector, current_profile)
	_change_phase(Phases.ACTIVE)


func exit():
	owner_node.facing_locked = false


func process_physics(delta: float, walk_direction: float, is_running: bool):
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

func allow_dodge() -> bool:
	return false

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
