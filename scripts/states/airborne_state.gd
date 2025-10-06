class_name AirborneState
extends State

var current_profile: JumpProfile

enum Phases { RISING, FALLING }
var current_phase: Phases = Phases.FALLING

var _last_jump_was_air: bool = false

var _pending_jump_impulse: bool = false
var _pending_initial_velocity: float = 0.0
var _holding: bool = false
var _hold_time: float = 0.0
var _released_this_frame: bool = false
var _ignore_air_control_this_frame: bool = false

var _landed_connected: bool = false

func enter(args: Dictionary = {}) -> void:
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

func exit() -> void:
	_holding = false
	_hold_time = 0.0
	_released_this_frame = false
	_pending_jump_impulse = false
	_pending_initial_velocity = 0.0
	_last_jump_was_air = false
	_ignore_air_control_this_frame = false

func on_jump_released() -> void:
	_holding = false
	_released_this_frame = true

func handle_jump_input(profile: JumpProfile) -> InputHandlerResult:
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

func handle_dash_input(_profile: DashProfile) -> InputHandlerResult:
	if owner_node.air_dash_used:
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)
	owner_node.air_dash_used = true
	return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

func process_physics(delta: float, walk_direction: float, _is_running: bool) -> Vector2:
	var current_walk_direction = walk_direction
	if _ignore_air_control_this_frame:
		current_walk_direction = 0.0
		_ignore_air_control_this_frame = false
		
	var new_velocity: Vector2 = owner_node.velocity

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
	_update_facing_sign(current_walk_direction)
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

func _update_facing_sign(direction: float) -> void:
	if owner_node.facing_locked:
		return
	if direction > 0.0:
		owner_node.facing_sign = 1
	elif direction < 0.0:
		owner_node.facing_sign = -1

func _update_phase(vel: Vector2 = Vector2.ZERO) -> void:
	var vy: float = owner_node.velocity.y
	if vel != Vector2.ZERO:
		vy = vel.y
	var new_phase: Phases = Phases.RISING if vy < 0.0 else Phases.FALLING
	if new_phase != current_phase:
		current_phase = new_phase
		_emit_phase_signal()

func _emit_phase_signal() -> void:
	if not current_profile:
		return
	var anim_to_play: StringName
	var sfx_to_play: AudioStream
	if current_phase == Phases.RISING:
		anim_to_play = current_profile.air_rising_animation if _last_jump_was_air and current_profile.air_rising_animation != StringName("") else current_profile.rising_animation
		sfx_to_play = current_profile.air_jump_sfx if _last_jump_was_air and current_profile.air_jump_sfx else current_profile.jump_sfx
	else:
		anim_to_play = current_profile.falling_animation
		sfx_to_play = current_profile.landing_sfx

	var phase_data := {
		"state_name": self.name,
		"phase_name": Phases.keys()[current_phase],
		"animation_to_play": anim_to_play,
		"sfx_to_play": sfx_to_play
	}
	state_machine.emit_phase_change(phase_data)

func _on_landed() -> void:
	owner_node.air_dash_used = false
	owner_node.air_jumps_left = 0
	owner_node.has_locked_air_pool = false
	owner_node.last_left_ground_ms = -1
