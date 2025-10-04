class_name LocomotionState
extends State

var current_profile: LocomotionProfile

enum Phases { IDLE, WALK, RUN }
var current_phase: Phases = Phases.IDLE

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")
	if not current_profile:
		push_warning("LocomotionState: Não recebeu um LocomotionProfile. A abortar.")
		return
	
	_change_phase(Phases.IDLE)

func process_physics(delta: float, walk_direction: float, is_running: bool) -> Vector2:
	var new_velocity = owner_node.velocity

	new_velocity = physics_component.apply_gravity(new_velocity, delta)

	if not current_profile:
		return new_velocity

	_update_facing_sign(walk_direction)
	
	var target_speed = current_profile.speed
	if is_running:
		target_speed = current_profile.run_speed
		
	if walk_direction != 0:
		new_velocity.x = walk_direction * target_speed
	else:
		new_velocity.x = move_toward(new_velocity.x, 0, current_profile.speed)
	
	_update_and_emit_phase(walk_direction, is_running)
	
	return new_velocity

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	if owner_node.is_on_floor():
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)
	
func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

func handle_sequence_skill_input(_skill_attack_set: AttackSet) -> InputHandlerResult:
	if owner_node.is_on_floor():
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func get_poise_shield_contribution() -> float:
	if not current_profile:
		return 0.0
	return current_profile.poise_shield_contribution

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
