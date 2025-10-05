class_name AirborneState
extends State

var current_profile: JumpProfile

enum Phases { RISING, FALLING }
var current_phase: Phases = Phases.FALLING

# --- NOVO: controle de coyote e pulos aéreos ---
var last_left_ground_ms: int = -1
var air_jumps_left: int = 0
var has_locked_air_pool: bool = false
var _last_jump_was_air: bool = false

# --- Lógica existente de pulo variável ---
var _pending_jump_impulse: bool = false
var _pending_initial_velocity: float = 0.0
var _holding: bool = false
var _hold_time: float = 0.0
var _released_this_frame: bool = false

func enter(args: Dictionary = {}) -> void:
	var apply_jump_impulse: bool = bool(args.get("apply_jump_impulse", false))
	current_profile = args.get("profile")
	_pending_jump_impulse = false
	_pending_initial_velocity = 0.0
	_holding = false
	_hold_time = 0.0
	_released_this_frame = false
	_last_jump_was_air = false

	if apply_jump_impulse and current_profile:
		# Primeiro pulo (do chão) entrando no Airborne
		_pending_jump_impulse = true
		_pending_initial_velocity = abs(current_profile.min_jump_velocity)
		_holding = true
		# Travar e carregar a pool aérea na primeira aceitação de pulo
		if not has_locked_air_pool:
			air_jumps_left = current_profile.max_air_jumps
			has_locked_air_pool = true
	else:
		# Entrou por queda (borda/escorregou) → inicia janela de coyote
		last_left_ground_ms = Time.get_ticks_msec()

	_update_phase(owner_node.velocity)

func exit() -> void:
	# Reset leve na saída (landing será o responsável pelo reset total)
	_holding = false
	_hold_time = 0.0
	_released_this_frame = false
	_pending_jump_impulse = false
	_pending_initial_velocity = 0.0
	_last_jump_was_air = false

func on_jump_released() -> void:
	_holding = false
	_released_this_frame = true

func handle_jump_input(profile: JumpProfile) -> InputHandlerResult:
	current_profile = profile
	if current_profile == null:
		return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

	var now_ms := Time.get_ticks_msec()
	var coyote_ms := int(current_profile.coyote_time * 1000.0)
	var in_coyote := (last_left_ground_ms >= 0) and ((now_ms - last_left_ground_ms) <= coyote_ms)

	if in_coyote:
		_pending_jump_impulse = true
		_pending_initial_velocity = abs(current_profile.min_jump_velocity)
		_holding = true
		_hold_time = 0.0
		_released_this_frame = false
		_last_jump_was_air = false

		if not has_locked_air_pool:
			air_jumps_left = current_profile.max_air_jumps
			has_locked_air_pool = true

		last_left_ground_ms = -1
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

	if air_jumps_left > 0:
		_pending_jump_impulse = true
		_pending_initial_velocity = abs(current_profile.min_jump_velocity)
		_holding = true
		_hold_time = 0.0
		_released_this_frame = false
		_last_jump_was_air = true

		if not has_locked_air_pool:
			air_jumps_left = max(current_profile.max_air_jumps - 1, 0)
			has_locked_air_pool = true
		else:
			air_jumps_left -= 1

		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED)

	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func process_physics(delta: float, walk_direction: float, _is_running: bool) -> Vector2:
	var new_velocity: Vector2 = owner_node.velocity

	if _pending_jump_impulse and current_profile:
		new_velocity.y = -abs(_pending_initial_velocity)
		_pending_jump_impulse = false
		last_left_ground_ms = -1

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
	if new_velocity.y > 0.0:
		var extra_down_a := 1600 * max(2.2 - 1.0, 0.0)
		new_velocity.y += extra_down_a * delta
	_update_facing_sign(walk_direction)
	_update_phase(new_velocity)

	if owner_node.is_on_floor() and new_velocity.y >= 0.0:
		# Landing → reset completo do ciclo aéreo
		air_jumps_left = 0
		has_locked_air_pool = false
		last_left_ground_ms = -1
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
