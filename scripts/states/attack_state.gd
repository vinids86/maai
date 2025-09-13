class_name AttackState
extends State

var current_profile: AttackProfile

enum Phases { STARTUP, ACTIVE, RECOVERY }
var current_phase: Phases
var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")

	if not current_profile:
		push_warning("AttackState: Não recebeu um AttackProfile para executar. A abortar.")
		state_machine.on_current_state_finished()
		return
	
	owner_node.facing_locked = true
	owner_node.velocity = Vector2.ZERO
	_change_phase(Phases.STARTUP)


func exit():
	owner_node.facing_locked = false


func process_physics(delta: float, is_running: bool = false):
	time_left_in_phase -= delta
	
	if time_left_in_phase <= 0:
		var time_exceeded = -time_left_in_phase
		
		match current_phase:
			Phases.STARTUP:
				_change_phase(Phases.ACTIVE)
				time_left_in_phase -= time_exceeded
			Phases.ACTIVE:
				_change_phase(Phases.RECOVERY)
				time_left_in_phase -= time_exceeded
			Phases.RECOVERY:
				state_machine.on_current_state_finished()
				return

func allow_dodge() -> bool:
	return false

func allow_attack() -> bool:
	return current_phase == Phases.RECOVERY

func _change_phase(new_phase: Phases):
	current_phase = new_phase
	
	var sfx_to_play: AudioStream
	match current_phase:
		Phases.STARTUP:
			time_left_in_phase = current_profile.startup_duration
			sfx_to_play = current_profile.startup_sfx
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
		"sfx_to_play": sfx_to_play
	}
	
	# A animação é enviada apenas uma vez, no início do ataque.
	if current_phase == Phases.STARTUP:
		phase_data["animation_to_play"] = current_profile.animation_name
	
	state_machine.emit_phase_change(phase_data)
