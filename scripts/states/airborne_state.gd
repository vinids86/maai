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
var _wall_jump_lock_timer: float = 0.0
var _coyote_timer: float = 0.0
var _is_gravity_suspended: bool = false
var _current_attack_has_hit: bool = false
var _attack_executor: AttackExecutor
var _air_combo_component: AirComboComponent
var _air_mobility_component: AirMobilityComponent
var _is_initialized: bool = false

func _initialize_references():
	if _is_initialized: return
	_attack_executor = owner_node.find_child("AttackExecutor")
	_air_combo_component = owner_node.find_child("AirComboComponent")
	_air_mobility_component = owner_node.find_child("AirMobilityComponent")
	_is_initialized = true

func enter(args: Dictionary = {}):
	_initialize_references()
	current_sub_state = SubStates.NORMAL

	var apply_jump_impulse: bool = bool(args.get("apply_jump_impulse", false))
	var is_wall_jump: bool = bool(args.get("is_wall_jump", false))
	current_profile = args.get("profile")
	
	if not current_profile and owner_node.has_method("get_jump_profile"):
		current_profile = owner_node.get_jump_profile()
	
	_pending_jump_impulse = false
	_pending_initial_velocity = 0.0
	_holding = false
	_hold_time = 0.0
	_released_this_frame = false
	_last_jump_was_air = false
	_wall_jump_lock_timer = 0.0
	_coyote_timer = 0.0 
	_is_gravity_suspended = false
	_current_attack_has_hit = false

	if is_wall_jump and current_profile:
		owner_node.velocity = current_profile.wall_jump_impulse * Vector2(-owner_node.facing_sign, 1)
		_holding = true
		_last_jump_was_air = true
		_wall_jump_lock_timer = current_profile.wall_jump_lock_duration
		
	elif apply_jump_impulse and current_profile:
		_pending_jump_impulse = true
		_pending_initial_velocity = abs(current_profile.min_jump_velocity)
		_holding = true
		
	else:
		if current_profile and args.get("allow_coyote", false):
			_coyote_timer = current_profile.coyote_time

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
	_is_gravity_suspended = false
	_current_attack_has_hit = false
	_coyote_timer = 0.0

func handle_attack_input(profile: AttackProfile) -> InputHandlerResult:
	if current_sub_state == SubStates.ATTACKING:
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)
	if not state_machine.action_cost_validator.try_pay_costs(profile):
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)
	_start_air_attack(profile)
	return InputHandlerResult.new(InputHandlerResult.Status.CONSUMED)

func process_physics(delta: float, walk_direction: float, _is_running: bool) -> Vector2:
	if _coyote_timer > 0:
		_coyote_timer -= delta

	var new_velocity = owner_node.velocity
	var current_walk_direction = walk_direction
	
	var is_control_locked = false
	if _wall_jump_lock_timer > 0.0:
		_wall_jump_lock_timer -= delta
		is_control_locked = true

	if _pending_jump_impulse and current_profile:
		new_velocity.y = -abs(_pending_initial_velocity)
		_pending_jump_impulse = false
		_coyote_timer = 0.0

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

	if not is_control_locked:
		if current_profile:
			new_velocity.x = current_walk_direction * current_profile.air_control_speed
		else:
			new_velocity.x = current_walk_direction * 200.0

	if not _is_gravity_suspended:
		new_velocity = physics_component.apply_gravity(new_velocity, delta)
		if new_velocity.y > 0.0:
			var extra_down_a := 1600 * max(2.2 - 1.0, 0.0)
			new_velocity.y += extra_down_a * delta
	else:
		new_velocity.y = 0.0

	_update_facing_sign(walk_direction)
	_update_phase(new_velocity)

	if owner_node.is_on_floor() and new_velocity.y >= 0.0:
		new_velocity.y = 0.0
		state_machine.on_current_state_finished()
		return new_velocity

	var is_falling = new_velocity.y > 0
	if is_falling and walk_direction != 0:
		var direction_sign = int(sign(walk_direction))
		var is_pressing_towards_wall = direction_sign == owner_node.facing_sign
		if is_pressing_towards_wall and wall_detector.is_colliding(direction_sign):
			state_machine.on_current_state_finished({"outcome": "WALL_CONTACT"})
			return new_velocity

	return new_velocity

func handle_jump_input(profile: JumpProfile) -> InputHandlerResult:
	var executor_phase_name = _attack_executor.get_current_phase_name()
	var can_cancel = (executor_phase_name == "RECOVERY")

	if current_sub_state == SubStates.ATTACKING and not can_cancel:
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)
		
	current_profile = profile
	if current_profile == null:
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

	if _coyote_timer > 0.0:
		_pending_jump_impulse = true
		_pending_initial_velocity = abs(current_profile.min_jump_velocity)
		_holding = true
		_hold_time = 0.0
		_released_this_frame = false
		_last_jump_was_air = false
		_coyote_timer = 0.0
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

	if _air_mobility_component.try_consume_air_jump():
		_pending_jump_impulse = true
		_pending_initial_velocity = abs(current_profile.min_jump_velocity)
		_holding = true
		_hold_time = 0.0
		_released_this_frame = false
		_last_jump_was_air = true
		_coyote_timer = 0.0
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dash_input(_profile: DashProfile) -> InputHandlerResult:
	var executor_phase_name = _attack_executor.get_current_phase_name()
	var can_cancel = (executor_phase_name == "RECOVERY")
	if current_sub_state == SubStates.NORMAL or (current_sub_state == SubStates.ATTACKING and can_cancel):
		if owner_node.is_on_floor(): return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
		var targeting = owner_node.find_child("SmartTargetingComponent")
		if targeting and targeting.current_target: return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
		if _air_mobility_component.try_consume_air_dash(): return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func _start_air_attack(profile: AttackProfile):
	if current_sub_state == SubStates.ATTACKING:
		if _attack_executor.is_connected("finished", Callable(self, "_on_air_attack_finished")): _attack_executor.finished.disconnect(_on_air_attack_finished)
		if _attack_executor.is_connected("attack_phase_changed", Callable(self, "_on_phase_changed")): _attack_executor.attack_phase_changed.disconnect(_on_phase_changed)
	current_sub_state = SubStates.ATTACKING
	_current_attack_has_hit = false
	_attack_executor.attack_phase_changed.connect(_on_phase_changed)
	_attack_executor.finished.connect(_on_air_attack_finished)
	_attack_executor.execute(profile)
	_air_combo_component.advance_combo()

func _on_air_attack_finished():
	if _attack_executor.is_connected("finished", Callable(self, "_on_air_attack_finished")): _attack_executor.finished.disconnect(_on_air_attack_finished)
	if _attack_executor.is_connected("attack_phase_changed", Callable(self, "_on_phase_changed")): _attack_executor.attack_phase_changed.disconnect(_on_phase_changed)
	if not _current_attack_has_hit: _is_gravity_suspended = false
	var buffered_data = state_machine.query_buffered_action()
	if buffered_data and buffered_data.action == BufferComponent.BufferedAction.ATTACK:
		var next_profile = _air_combo_component.get_next_attack_profile()
		if next_profile and state_machine.action_cost_validator.try_pay_costs(next_profile):
			_start_air_attack(next_profile)
			return
	current_sub_state = SubStates.NORMAL
	_is_gravity_suspended = false
	_update_phase(owner_node.velocity)

func handle_attack_outcome(outcome: ContactResult) -> void:
	var result = outcome.attacker_outcome
	if result == ContactResult.AttackerOutcome.HIT_SUCCESS_SIMPLE_ENEMY:
		_is_gravity_suspended = true
		_current_attack_has_hit = true
		owner_node.velocity.y = 0.0

func _on_phase_changed(phase_data: Dictionary): state_machine.emit_phase_change(phase_data)

func get_poise_shield_contribution() -> float:
	if current_sub_state == SubStates.ATTACKING:
		var executor_phase = _attack_executor.get_current_phase_name()
		var profile = _attack_executor.get_current_profile()
		if profile: match executor_phase:
				"STARTUP": return profile.startup_poise_shield
				"ACTIVE": return profile.active_poise_shield
				"RECOVERY": return profile.recovery_poise_shield
	return 0.0

func on_jump_released() -> void: _holding = false; _released_this_frame = true
func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult: return InputHandlerResult.new(InputHandlerResult.Status.CONSUMED)
func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult: return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

func _update_facing_sign(direction: float) -> void:
	if owner_node.facing_locked: return
	if direction > 0.0: owner_node.facing_sign = 1
	elif direction < 0.0: owner_node.facing_sign = -1

func _update_phase(vel: Vector2 = Vector2.ZERO) -> void:
	if current_sub_state == SubStates.ATTACKING: return
	var vy: float = owner_node.velocity.y
	if vel != Vector2.ZERO: vy = vel.y
	var new_phase: JumpPhases = JumpPhases.RISING if vy < 0.0 else JumpPhases.FALLING
	if new_phase != current_jump_phase:
		current_jump_phase = new_phase
		_emit_phase_signal()

func _emit_phase_signal() -> void:
	if not current_profile: return
	var anim_to_play: StringName; var sfx_to_play: AudioStream
	if current_jump_phase == JumpPhases.RISING:
		anim_to_play = current_profile.air_rising_animation if _last_jump_was_air and current_profile.air_rising_animation != StringName("") else current_profile.rising_animation
		sfx_to_play = current_profile.air_jump_sfx if _last_jump_was_air and current_profile.air_jump_sfx else current_profile.jump_sfx
	else:
		anim_to_play = current_profile.falling_animation
		sfx_to_play = current_profile.landing_sfx
	state_machine.emit_phase_change({"state_name": self.name, "phase_name": JumpPhases.keys()[current_jump_phase], "animation_to_play": anim_to_play, "sfx_to_play": sfx_to_play})
