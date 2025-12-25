class_name AirborneState
extends State

var current_profile: JumpProfile

enum JumpPhases { RISING, FALLING }
var current_jump_phase: JumpPhases = JumpPhases.FALLING

var _last_jump_was_air: bool = false
var _pending_jump_impulse: bool = false
var _pending_initial_velocity: float = 0.0
var _holding: bool = false
var _hold_time: float = 0.0
var _released_this_frame: bool = false
var _wall_jump_lock_timer: float = 0.0

# Coyote Time
var _coyote_timer: float = 0.0

var _air_mobility_component: AirMobilityComponent
var _is_initialized: bool = false

func _initialize_references():
	if _is_initialized: return
	_air_mobility_component = owner_node.find_child("AirMobilityComponent")
	_is_initialized = true

func enter(args: Dictionary = {}):
	_initialize_references()
	
	var do_jump: bool = bool(args.get("do_jump", false))
	var apply_impulse: bool = bool(args.get("apply_jump_impulse", false))
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

	if is_wall_jump and current_profile:
		owner_node.velocity = current_profile.wall_jump_impulse * Vector2(-owner_node.facing_sign, 1)
		_holding = true
		_last_jump_was_air = true
		_wall_jump_lock_timer = current_profile.wall_jump_lock_duration
		
	elif (do_jump or apply_impulse) and current_profile:
		_pending_jump_impulse = true
		_pending_initial_velocity = abs(current_profile.min_jump_velocity)
		_holding = true
		
	else:
		if current_profile and args.get("allow_coyote", false):
			_coyote_timer = current_profile.coyote_time

	_update_phase(owner_node.velocity)

func exit():
	_holding = false
	_hold_time = 0.0
	_released_this_frame = false
	_pending_jump_impulse = false
	_coyote_timer = 0.0

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

	new_velocity = physics_component.apply_gravity(new_velocity, delta)
	
	if new_velocity.y > 0.0:
		var extra_down_a := 1600 * max(2.2 - 1.0, 0.0)
		new_velocity.y += extra_down_a * delta

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
	current_profile = profile
	if current_profile == null:
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

	if _coyote_timer > 0.0:
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
		return InputHandlerResult.new(InputHandlerResult.Status.CONSUMED)

	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_attack_input(profile: AttackProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

func handle_dash_input(_profile: DashProfile) -> InputHandlerResult:
	# Prioridade: Se tiver alvo (grapple/hook), permite dash sem gastar recurso
	var targeting = owner_node.find_child("SmartTargetingComponent")
	if targeting and targeting.current_target:
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

	# Se não tiver alvo, tenta gastar recurso aéreo
	if _air_mobility_component.try_consume_air_dash():
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)
		
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func on_jump_released() -> void:
	_holding = false
	_released_this_frame = true

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.CONSUMED)

func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

func _update_facing_sign(direction: float) -> void:
	if owner_node.facing_locked: return
	if direction > 0.0: owner_node.facing_sign = 1
	elif direction < 0.0: owner_node.facing_sign = -1

func _update_phase(vel: Vector2 = Vector2.ZERO) -> void:
	var vy: float = owner_node.velocity.y
	if vel != Vector2.ZERO: vy = vel.y
	var new_phase: JumpPhases = JumpPhases.RISING if vy < 0.0 else JumpPhases.FALLING
	if new_phase != current_jump_phase:
		current_jump_phase = new_phase
		_emit_phase_signal()

func _emit_phase_signal() -> void:
	if not current_profile: return
	var anim_to_play: StringName
	var sfx_to_play: AudioStream
	if current_jump_phase == JumpPhases.RISING:
		anim_to_play = current_profile.air_rising_animation if _last_jump_was_air and current_profile.air_rising_animation != StringName("") else current_profile.rising_animation
		sfx_to_play = current_profile.air_jump_sfx if _last_jump_was_air and current_profile.air_jump_sfx else current_profile.jump_sfx
	else:
		anim_to_play = current_profile.falling_animation
		sfx_to_play = current_profile.landing_sfx
	state_machine.emit_phase_change({"state_name": self.name, "phase_name": JumpPhases.keys()[current_jump_phase], "animation_to_play": anim_to_play, "sfx_to_play": sfx_to_play})
