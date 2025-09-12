class_name DodgeState
extends State

@export var neutral_dodge_profile: DodgeProfile
@export var forward_dodge_profile: DodgeProfile
@export var back_dodge_profile: DodgeProfile
@export var up_dodge_profile: DodgeProfile
@export var down_dodge_profile: DodgeProfile

enum Phases { ACTIVE, RECOVERY }
var current_phase: Phases
var time_left_in_phase: float = 0.0

var current_profile: DodgeProfile

func enter(args: Dictionary = {}):
	owner_node.facing_locked = true
	var direction_vector = args.get("direction", Vector2.ZERO)
	
	current_profile = _select_profile_from_direction(direction_vector)

	if not current_profile:
		push_warning("DodgeState: Nenhum perfil de esquiva encontrado. A abortar.")
		state_machine.on_current_state_finished()
		return
		
	movement_component.apply_dodge_velocity(direction_vector, current_profile)
	_change_phase(Phases.ACTIVE)


func exit():
	owner_node.facing_locked = false


func process_physics(delta: float, is_running: bool = false):
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
	
	match current_phase:
		Phases.ACTIVE:
			time_left_in_phase = current_profile.active_duration
		Phases.RECOVERY:
			time_left_in_phase = current_profile.recovery_duration

func _select_profile_from_direction(direction: Vector2) -> DodgeProfile:
	if direction.y < 0:
		return up_dodge_profile
	elif direction.y > 0:
		return down_dodge_profile
	elif direction.x != 0:
		if direction.x * owner_node.facing_sign > 0:
			return forward_dodge_profile
		else:
			return back_dodge_profile
	else:
		return neutral_dodge_profile
