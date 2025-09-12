class_name AttackState
extends State

@export var attack_profile: AttackProfile

enum Phases { STARTUP, ACTIVE, RECOVERY }
var current_phase: Phases
var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	if not attack_profile:
		push_warning("AttackState: Nenhum AttackProfile foi atribuído. A abortar.")
		state_machine.on_current_state_finished()
		return
	
	owner_node.facing_locked = true
	owner_node.velocity = Vector2.ZERO # O personagem para de se mover para atacar.
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
	# Permite que um novo ataque seja 'bufferizado' apenas durante a fase de recuperação.
	return current_phase == Phases.RECOVERY

func _change_phase(new_phase: Phases):
	current_phase = new_phase
	
	match current_phase:
		Phases.STARTUP:
			time_left_in_phase = attack_profile.startup_duration
		Phases.ACTIVE:
			time_left_in_phase = attack_profile.active_duration
		Phases.RECOVERY:
			time_left_in_phase = attack_profile.recovery_duration
