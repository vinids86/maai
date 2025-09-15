class_name LocomotionState
extends State

var current_profile: LocomotionProfile

enum Phases { IDLE, WALK, RUN }
var current_phase: Phases = Phases.IDLE

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")
	if not current_profile:
		push_warning("LocomotionState: Não recebeu um LocomotionProfile. A abortar.")
		return
	
	_change_phase(Phases.IDLE)


func process_physics(delta: float, walk_direction: float, is_running: bool):
	if not owner_node.is_on_floor():
		owner_node.velocity.y += gravity * delta

	if not current_profile:
		return

	_update_facing_sign(walk_direction)
	
	movement_component.calculate_walk_velocity(walk_direction, is_running, current_profile)
	
	_update_and_emit_phase(walk_direction, is_running)

func get_current_poise() -> float:
	if not current_profile:
		return 0.0
	return current_profile.base_poise

func allow_dodge() -> bool:
	return owner_node.is_on_floor()

func can_initiate_attack() -> bool:
	return owner_node.is_on_floor()

func can_buffer_attack() -> bool:
	return false
	
func allow_autoblock() -> bool:
	return true

func _update_facing_sign(direction: float):
	if owner_node.facing_locked:
		return
		
	if direction > 0:
		owner_node.facing_sign = 1
	elif direction < 0:
		owner_node.facing_sign = -1

func _update_and_emit_phase(walk_direction: float, is_running: bool):
	var new_phase: Phases
	
	if walk_direction == 0:
		new_phase = Phases.IDLE
	elif is_running:
		new_phase = Phases.RUN
	else:
		new_phase = Phases.WALK
		
	if new_phase != current_phase:
		_change_phase(new_phase)

func _change_phase(new_phase: Phases):
	current_phase = new_phase
	
	var anim_to_play: StringName
	match current_phase:
		Phases.IDLE:
			anim_to_play = current_profile.idle_animation
		Phases.WALK:
			anim_to_play = current_profile.walk_animation
		Phases.RUN:
			anim_to_play = current_profile.run_animation
	
	var phase_data = {
		"state_name": self.name,
		"phase_name": Phases.keys()[current_phase],
		"profile": current_profile,
		"animation_to_play": anim_to_play
	}
	
	state_machine.emit_phase_change(phase_data)
