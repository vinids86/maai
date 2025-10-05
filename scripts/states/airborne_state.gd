class_name AirborneState
extends State

var current_profile: JumpProfile

enum Phases { RISING, FALLING }
var current_phase: Phases = Phases.FALLING

var _pending_jump_impulse: bool = false
var _holding: bool = false
var _hold_time: float = 0.0
var _released_this_frame: bool = false

func enter(args: Dictionary = {}) -> void:
	var apply_jump_impulse: bool = bool(args.get("apply_jump_impulse", false))
	current_profile = args.get("profile")
	_pending_jump_impulse = apply_jump_impulse
	_holding = true
	_hold_time = 0.0
	_released_this_frame = false
	_update_phase(owner_node.velocity)

func on_jump_released() -> void:
	_holding = false
	_released_this_frame = true

func process_physics(delta: float, walk_direction: float, _is_running: bool) -> Vector2:
	var new_velocity: Vector2 = owner_node.velocity

	if _pending_jump_impulse and current_profile:
		new_velocity.y = -abs(current_profile.min_jump_velocity)
		_pending_jump_impulse = false

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
		new_velocity.x = walk_direction * current_profile.air_control_speed
	else:
		new_velocity.x = walk_direction * 200.0

	new_velocity = physics_component.apply_gravity(new_velocity, delta)

	_update_facing_sign(walk_direction)
	_update_phase(new_velocity)

	if owner_node.is_on_floor() and new_velocity.y >= 0.0:
		state_machine.on_current_state_finished()
		return Vector2.ZERO

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
	var anim_to_play: StringName = current_profile.rising_animation if current_phase == Phases.RISING else current_profile.falling_animation
	var sfx_to_play: AudioStream = current_profile.jump_sfx if current_phase == Phases.RISING else current_profile.landing_sfx
	var phase_data := {
		"state_name": self.name,
		"phase_name": Phases.keys()[current_phase],
		"animation_to_play": anim_to_play,
		"sfx_to_play": sfx_to_play
	}
	state_machine.emit_phase_change(phase_data)
