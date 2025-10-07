class_name AirborneState
extends State

var current_profile: JumpProfile

enum JumpPhases { RISING, FALLING }
var current_jump_phase: JumpPhases = JumpPhases.FALLING

enum SubStates { NORMAL, ATTACKING }
var current_sub_state: SubStates = SubStates.NORMAL

var _last_jump_was_air: bool = false

var _pending_jump_impulse: bool = false
var _pending_initial_velocity: float = 0.0
var _holding: bool = false
var _hold_time: float = 0.0
var _released_this_frame: bool = false
var _ignore_air_control_this_frame: bool = false

var _landed_connected: bool = false

var _attack_executor: AttackExecutor
var _air_combo_component: AirComboComponent
var _is_initialized: bool = false


func _initialize_references():
	if _is_initialized:
		return
	_attack_executor = owner_node.find_child("AttackExecutor")
	_air_combo_component = owner_node.find_child("AirComboComponent")
	assert(_attack_executor != null, "AirborneState: Nó 'AttackExecutor' não encontrado.")
	assert(_air_combo_component != null, "AirborneState: Nó 'AirComboComponent' não encontrado.")
	_is_initialized = true


func enter(args: Dictionary = {}):
	_initialize_references()
	current_sub_state = SubStates.NORMAL

	var apply_jump_impulse: bool = bool(args.get("apply_jump_impulse", false))
	var is_wall_jump: bool = bool(args.get("is_wall_jump", false))
	
	current_profile = args.get("profile")
	_pending_jump_impulse = false
	_pending_initial_velocity = 0.0
	_holding = false
	_hold_time = 0.0
	_released_this_frame = false
	_last_jump_was_air = false
	_ignore_air_control_this_frame = false

	if surface_contact_component and not _landed_connected:
		surface_contact_component.connect("landed", Callable(self, "_on_landed"))
		_landed_connected = true

	if is_wall_jump and current_profile:
		owner_node.velocity = current_profile.wall_jump_impulse * Vector2(owner_node.facing_sign, 1)
		_holding = true
		_last_jump_was_air = true
		_ignore_air_control_this_frame = true
	elif apply_jump_impulse and current_profile:
		_pending_jump_impulse = true
		_pending_initial_velocity = abs(current_profile.min_jump_velocity)
		_holding = true
		if not owner_node.has_locked_air_pool:
			owner_node.air_jumps_left = current_profile.max_air_jumps
			owner_node.has_locked_air_pool = true
	else:
		if surface_contact_component.last_left_ground_ms != -1:
			owner_node.last_left_ground_ms = surface_contact_component.last_left_ground_ms

	_update_phase(owner_node.velocity)


func exit():
	if current_sub_state == SubStates.ATTACKING:
		_attack_executor.stop()
		if _attack_executor.is_connected("finished", Callable(self, "_on_air_attack_finished")):
			_attack_executor.finished.disconnect(_on_air_attack_finished)
		if _attack_executor.is_connected("attack_phase_changed", Callable(self, "_on_phase_changed")):
			_attack_executor.attack_phase_changed.disconnect(_on_phase_changed)
	
	_holding = false
	_hold_time = 0.0
	_released_this_frame = false
	_pending_jump_impulse = false
	_pending_initial_velocity = 0.0
	_last_jump_was_air = false
	_ignore_air_control_this_frame = false


func handle_attack_input(profile: AttackProfile) -> InputHandlerResult:
	# Se já estiver a atacar, rejeita sempre para que o buffer funcione
	if current_sub_state == SubStates.ATTACKING:
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

	if not state_machine.action_cost_validator.try_pay_costs(profile):
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)
	
	_start_air_attack(profile)
	return InputHandlerResult.new(InputHandlerResult.Status.CONSUMED)


func process_physics(delta: float, walk_direction: float, _is_running: bool) -> Vector2:
	var new_velocity: Vector2

	if current_sub_state == SubStates.ATTACKING:
		new_velocity = _attack_executor.get_physics_movement_velocity()
	else:
		var current_walk_direction = walk_direction
		if _ignore_air_control_this_frame:
			current_walk_direction = 0.0
			_ignore_air_control_this_frame = false
		
		new_velocity = owner_node.velocity

		if _pending_jump_impulse and current_profile:
			new_velocity.y = -abs(_pending_initial_velocity)
			_pending_jump_impulse = false
			owner_node.last_left_ground_ms = -1

		if current_profile:
			if _holding and _hold_time < current_profile.max_hold_time and new_velocity.y < 0.0:
				new_velocity.y -= current_profile.hold_accel * delta
				if abs(new_velocity.y) > abs(current_profile.max_jump_velocity):
					new_velocity.y = -abs(current_profile.max_jump_velocity)
				_hold_time += delta
			if _released_this_frame and new_velocity.y < 0.0:
				new_velocity.y *= current_profile.release_cut_multiplier
				_released_this_frame = false
		else:
			if _holding and _hold_time < 0.12 and new_velocity.y < 0.0:
				_hold_time += delta

		if current_profile:
			new_velocity.x = current_walk_direction * current_profile.air_control_speed
		else:
			new_velocity.x = current_walk_direction * 200.0

	new_velocity = physics_component.apply_gravity(new_velocity, delta)
	if new_velocity.y > 0.0:
		var extra_down_a := 1600 * max(2.2 - 1.0, 0.0)
		new_velocity.y += extra_down_a * delta
		
	_update_facing_sign(walk_direction)
	_update_phase(new_velocity)

	if owner_node.is_on_floor() and new_velocity.y >= 0.0:
		_on_landed()
		state_machine.on_current_state_finished()
		return Vector2.ZERO

	var is_falling = new_velocity.y > 0
	if is_falling and walk_direction != 0:
		var direction_sign = int(sign(walk_direction))
		var is_pressing_towards_wall = direction_sign == owner_node.facing_sign
		if is_pressing_towards_wall and wall_detector.is_colliding(direction_sign):
			state_machine.on_current_state_finished({"outcome": "WALL_CONTACT"})
			return new_velocity

	return new_velocity

func _start_air_attack(profile: AttackProfile):
	if current_sub_state == SubStates.ATTACKING:
		if _attack_executor.is_connected("finished", Callable(self, "_on_air_attack_finished")):
			_attack_executor.finished.disconnect(_on_air_attack_finished)
		if _attack_executor.is_connected("attack_phase_changed", Callable(self, "_on_phase_changed")):
			_attack_executor.attack_phase_changed.disconnect(_on_phase_changed)

	current_sub_state = SubStates.ATTACKING
	_attack_executor.attack_phase_changed.connect(_on_phase_changed)
	_attack_executor.finished.connect(_on_air_attack_finished)
	_attack_executor.execute(profile)
	_air_combo_component.advance_combo()

func _on_air_attack_finished():
	if _attack_executor.is_connected("finished", Callable(self, "_on_air_attack_finished")):
		_attack_executor.finished.disconnect(_on_air_attack_finished)
	if _attack_executor.is_connected("attack_phase_changed", Callable(self, "_on_phase_changed")):
		_attack_executor.attack_phase_changed.disconnect(_on_phase_changed)
	
	current_sub_state = SubStates.NORMAL
	
	var buffered_data = state_machine.buffer_component.consume()
	if buffered_data and buffered_data.action == BufferComponent.BufferedAction.ATTACK:
		var next_profile = _air_combo_component.get_next_attack_profile()
		if next_profile and state_machine.action_cost_validator.try_pay_costs(next_profile):
			_start_air_attack(next_profile)
			return

	_update_phase(owner_node.velocity)

func _on_phase_changed(phase_data: Dictionary):
	state_machine.emit_phase_change(phase_data)
	
func get_poise_shield_contribution() -> float:
	if current_sub_state == SubStates.ATTACKING:
		var executor_phase = _attack_executor.get_current_phase_name()
		var profile = _attack_executor.get_current_profile()
		if profile:
			match executor_phase:
				"STARTUP": return profile.startup_poise_shield
				"ACTIVE": return profile.active_poise_shield
				"RECOVERY": return profile.recovery_poise_shield
	return 0.0

func on_jump_released() -> void:
	_holding = false
	_released_this_frame = true

func handle_jump_input(profile: JumpProfile) -> InputHandlerResult:
	var executor_phase_name = _attack_executor.get_current_phase_name()
	var can_cancel = (executor_phase_name == "RECOVERY")

	# Rejeita o pulo se estiver a atacar E não estiver na fase de recuperação
	if current_sub_state == SubStates.ATTACKING and not can_cancel:
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)
		
	current_profile = profile
	if current_profile == null:
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

	var now_ms := Time.get_ticks_msec()
	var coyote_ms := int(current_profile.coyote_time * 1000.0)
	var in_coyote = (owner_node.last_left_ground_ms >= 0) and ((now_ms - owner_node.last_left_ground_ms) <= coyote_ms)

	if in_coyote:
		_pending_jump_impulse = true
		_pending_initial_velocity = abs(current_profile.min_jump_velocity)
		_holding = true
		_hold_time = 0.0
		_released_this_frame = false
		_last_jump_was_air = false

		if not owner_node.has_locked_air_pool:
			owner_node.air_jumps_left = current_profile.max_air_jumps
			owner_node.has_locked_air_pool = true

		owner_node.last_left_ground_ms = -1
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

	if not owner_node.has_locked_air_pool and current_profile.max_air_jumps > 0:
		_pending_jump_impulse = true
		_pending_initial_velocity = abs(current_profile.min_jump_velocity)
		_holding = true
		_hold_time = 0.0
		_released_this_frame = false
		_last_jump_was_air = true

		owner_node.has_locked_air_pool = true
		owner_node.air_jumps_left = max(current_profile.max_air_jumps - 1, 0)
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

	if owner_node.air_jumps_left > 0:
		_pending_jump_impulse = true
		_pending_initial_velocity = abs(current_profile.min_jump_velocity)
		_holding = true
		_hold_time = 0.0
		_released_this_frame = false
		_last_jump_was_air = true

		owner_node.air_jumps_left -= 1
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	var executor_phase_name = _attack_executor.get_current_phase_name()
	var can_cancel = (executor_phase_name == "RECOVERY")

	if current_sub_state == SubStates.NORMAL or (current_sub_state == SubStates.ATTACKING and can_cancel):
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dash_input(_profile: DashProfile) -> InputHandlerResult:
	var executor_phase_name = _attack_executor.get_current_phase_name()
	var can_cancel = (executor_phase_name == "RECOVERY")

	if current_sub_state == SubStates.NORMAL or (current_sub_state == SubStates.ATTACKING and can_cancel):
		if owner_node.air_dash_used:
			return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)
		owner_node.air_dash_used = true
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func _update_facing_sign(direction: float) -> void:
	if owner_node.facing_locked:
		return
	if direction > 0.0:
		owner_node.facing_sign = 1
	elif direction < 0.0:
		owner_node.facing_sign = -1

func _update_phase(vel: Vector2 = Vector2.ZERO) -> void:
	if current_sub_state == SubStates.ATTACKING:
		return
		
	var vy: float = owner_node.velocity.y
	if vel != Vector2.ZERO:
		vy = vel.y
	var new_phase: JumpPhases = JumpPhases.RISING if vy < 0.0 else JumpPhases.FALLING
	if new_phase != current_jump_phase:
		current_jump_phase = new_phase
		_emit_phase_signal()

func _emit_phase_signal() -> void:
	if not current_profile:
		return
	var anim_to_play: StringName
	var sfx_to_play: AudioStream
	if current_jump_phase == JumpPhases.RISING:
		anim_to_play = current_profile.air_rising_animation if _last_jump_was_air and current_profile.air_rising_animation != StringName("") else current_profile.rising_animation
		sfx_to_play = current_profile.air_jump_sfx if _last_jump_was_air and current_profile.air_jump_sfx else current_profile.jump_sfx
	else:
		anim_to_play = current_profile.falling_animation
		sfx_to_play = current_profile.landing_sfx

	var phase_data := {
		"state_name": self.name,
		"phase_name": JumpPhases.keys()[current_jump_phase],
		"animation_to_play": anim_to_play,
		"sfx_to_play": sfx_to_play
	}
	state_machine.emit_phase_change(phase_data)

func _on_landed() -> void:
	owner_node.air_dash_used = false
	owner_node.air_jumps_left = 0
	owner_node.has_locked_air_pool = false
	owner_node.last_left_ground_ms = -1
