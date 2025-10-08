class_name DashState
extends State

var current_profile: DashProfile

enum Phases { ACTIVE, RECOVERY, ATTACKING }
var current_phase: Phases
var time_left_in_phase: float = 0.0

var _attack_executor: AttackExecutor
var _is_initialized: bool = false

func _initialize_references():
	if _is_initialized:
		return
	_attack_executor = owner_node.find_child("AttackExecutor")
	assert(_attack_executor != null, "DashState: Nó 'AttackExecutor' não encontrado.")
	_is_initialized = true


func enter(args: Dictionary = {}):
	_initialize_references()
	owner_node.facing_locked = true
	
	self.current_profile = args.get("profile")
	if not current_profile:
		state_machine.on_current_state_finished()
		return

	if path_follower_component and owner_node.path_target:
		owner_node.path_target.position = Vector2.ZERO
		path_follower_component.start_following(owner_node.path_target)
		
	_change_phase(Phases.ACTIVE)

func exit():
	owner_node.facing_locked = false

	if path_follower_component:
		path_follower_component.stop_following()

	if _attack_executor and current_phase == Phases.ATTACKING:
		_attack_executor.stop()
		if _attack_executor.is_connected("finished", Callable(self, "_on_attack_finished")):
			_attack_executor.finished.disconnect(_on_attack_finished)
		if _attack_executor.is_connected("attack_phase_changed", Callable(self, "_on_phase_changed")):
			_attack_executor.attack_phase_changed.disconnect(_on_phase_changed)


func process_physics(delta: float, _walk_direction: float, _is_running: bool) -> Vector2:
	if not current_profile:
		return Vector2.ZERO

	var calculated_velocity = Vector2.ZERO

	match current_phase:
		Phases.ACTIVE, Phases.RECOVERY:
			if path_follower_component and path_follower_component.is_active():
				calculated_velocity = path_follower_component.calculate_target_velocity(delta)
		Phases.ATTACKING:
			if _attack_executor:
				calculated_velocity = _attack_executor.get_physics_movement_velocity()

	time_left_in_phase -= delta
	
	if time_left_in_phase <= 0:
		if current_phase == Phases.ACTIVE:
			_change_phase(Phases.RECOVERY)
		elif current_phase == Phases.RECOVERY:
			var buffered_data = state_machine.query_buffered_action()
			if buffered_data and buffered_data.action == BufferComponent.BufferedAction.ATTACK:
				_start_dash_attack(buffered_data.context.get("profile"))
			else:
				state_machine.on_current_state_finished()
				return Vector2.ZERO
	
	if not owner_node.is_on_floor():
		calculated_velocity = physics_component.apply_gravity(calculated_velocity, delta)
	
	return calculated_velocity

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	var dash_attack_profile = owner_node.dash_attack_profile
	if not dash_attack_profile:
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

	if current_phase == Phases.ACTIVE or current_phase == Phases.RECOVERY:
		var context = {"override_profile": dash_attack_profile}
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED, context)
		
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func resolve_contact(context: ContactContext) -> ContactResult:
	return _resolve_default_contact(context)

func get_poise_shield_contribution() -> float:
	if current_phase == Phases.ATTACKING:
		var profile = _attack_executor.get_current_profile()
		if profile:
			match _attack_executor.get_current_phase_name():
				"STARTUP": return profile.startup_poise_shield
				"ACTIVE": return profile.active_poise_shield
				"RECOVERY": return profile.recovery_poise_shield
	return 0.0

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
		Phases.ATTACKING:
			return

	var phase_data = {
		"state_name": self.name,
		"phase_name": Phases.keys()[current_phase],
		"profile": current_profile,
		"animation_to_play": current_profile.animation_name,
		"sfx_to_play": sfx_to_play
	}
	state_machine.emit_phase_change(phase_data)

func _start_dash_attack(profile: AttackProfile):
	if not profile or not state_machine.action_cost_validator.try_pay_costs(profile):
		state_machine.on_current_state_finished()
		return
	
	if path_follower_component:
		path_follower_component.stop_following()

	_change_phase(Phases.ATTACKING)
	_attack_executor.attack_phase_changed.connect(_on_phase_changed)
	_attack_executor.finished.connect(_on_attack_finished)
	_attack_executor.execute(profile)
	
func _on_phase_changed(phase_data: Dictionary):
	state_machine.emit_phase_change(phase_data)
	
func _on_attack_finished():
	state_machine.on_current_state_finished()
