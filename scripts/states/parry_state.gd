class_name ParryState
extends State

var current_profile: ParryProfile

enum Phases { ACTIVE, SUCCESS, RECOVERY }
var current_phase: Phases
var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")
	
	if not current_profile:
		push_warning("ParryState: Não recebeu um ParryProfile para executar. A abortar.")
		state_machine.on_current_state_finished()
		return
	
	owner_node.facing_locked = true
	owner_node.velocity = Vector2.ZERO
	_change_phase(Phases.ACTIVE)


func exit():
	owner_node.facing_locked = false


func process_physics(delta: float, walk_direction: float, is_running: bool):
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

func is_in_active_phase() -> bool:
	return current_phase == Phases.ACTIVE

func on_parry_success():
	if current_phase == Phases.ACTIVE:
		_change_phase(Phases.SUCCESS)

func _change_phase(new_phase: Phases):
	current_phase = new_phase
	
	var sfx_to_play: AudioStream
	match current_phase:
		Phases.ACTIVE:
			time_left_in_phase = current_profile.active_duration
			sfx_to_play = current_profile.active_sfx
		Phases.SUCCESS:
			time_left_in_phase = 0.1
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

func allow_attack() -> bool:
	return false

func can_buffer_attack() -> bool:
	return current_phase == Phases.SUCCESS or current_phase == Phases.RECOVERY

func allow_autoblock() -> bool: 
	return current_phase == Phases.RECOVERY
