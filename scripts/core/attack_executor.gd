class_name AttackExecutor
extends Node

signal attack_phase_changed(phase_data: Dictionary)
signal finished

var _owner_node: Node
var _hitbox: Area2D
var _hitbox_shape: CollisionShape2D
var _current_profile: AttackProfile

enum Phases { STARTUP, ACTIVE, RECOVERY, NONE }
var _current_phase: Phases = Phases.NONE
var _time_left_in_phase: float = 0.0

func _ready():
	set_physics_process(false)

func setup(owner: Node):
	self._owner_node = owner
	_hitbox = owner.find_child("AttackHitbox") as Area2D
	if _hitbox:
		_hitbox_shape = _hitbox.find_child("CollisionShape2D") as CollisionShape2D
	
	assert(_hitbox != null, "AttackExecutor: Nó 'AttackHitbox' não encontrado.")
	assert(_hitbox_shape != null, "AttackExecutor: Nó 'CollisionShape2D' não encontrado.")

func _physics_process(delta: float):
	if _current_phase == Phases.NONE:
		return

	_time_left_in_phase -= delta
	
	if _time_left_in_phase <= 0.0:
		var time_exceeded: float = -_time_left_in_phase
		match _current_phase:
			Phases.STARTUP:
				_change_phase(Phases.ACTIVE)
				_time_left_in_phase -= time_exceeded
			Phases.ACTIVE:
				_change_phase(Phases.RECOVERY)
				_time_left_in_phase -= time_exceeded
			Phases.RECOVERY:
				_stop_execution()
				emit_signal("finished")
				return

	var move_vel = Vector2.ZERO
	match _current_phase:
		Phases.STARTUP:
			move_vel = _current_profile.startup_movement_velocity
		Phases.ACTIVE:
			move_vel = _current_profile.active_movement_velocity
		Phases.RECOVERY:
			move_vel = _current_profile.recovery_movement_velocity
			
	_owner_node.velocity.x = move_vel.x * _owner_node.facing_sign
	_owner_node.velocity.y = move_vel.y

func execute(profile: AttackProfile):
	if not is_instance_valid(profile):
		push_warning("AttackExecutor: Tentou executar um AttackProfile inválido.")
		return
	
	self._current_profile = profile
	set_physics_process(true)
	_change_phase(Phases.STARTUP)

func stop():
	_stop_execution()

func get_current_profile() -> AttackProfile:
	return _current_profile

func get_current_phase_name() -> String:
	return Phases.keys()[_current_phase].to_upper()

func _stop_execution():
	set_physics_process(false)
	_current_phase = Phases.NONE
	_current_profile = null
	if _hitbox_shape and is_instance_valid(_hitbox_shape):
		_hitbox_shape.set_deferred("disabled", true)
		_hitbox_shape.shape = null
	
	# Reinicia a posição e a escala da hitbox para o seu estado padrão.
	if is_instance_valid(_hitbox):
		_hitbox.position = Vector2.ZERO
		_hitbox.scale = Vector2.ONE

func _change_phase(new_phase: Phases):
	_current_phase = new_phase
	
	var sfx_to_play: AudioStream
	match _current_phase:
		Phases.STARTUP:
			_time_left_in_phase = _current_profile.startup_duration
			sfx_to_play = _current_profile.startup_sfx
		Phases.ACTIVE:
			_time_left_in_phase = _current_profile.active_duration
			sfx_to_play = _current_profile.active_sfx
			_update_and_enable_hitbox()
		Phases.RECOVERY:
			_time_left_in_phase = _current_profile.recovery_duration
			sfx_to_play = _current_profile.recovery_sfx
			if _hitbox_shape:
				_hitbox_shape.set_deferred("disabled", true)
				_hitbox_shape.shape = null
	
	var phase_data: Dictionary = {
		"state_name": _owner_node.state_machine.current_state.name,
		"phase_name": get_current_phase_name(),
		"profile": _current_profile,
		"sfx_to_play": sfx_to_play
	}
	
	if _current_phase == Phases.STARTUP:
		phase_data["animation_to_play"] = _current_profile.animation_name
	
	emit_signal("attack_phase_changed", phase_data)

func _update_and_enable_hitbox():
	_hitbox.attack_profile = _current_profile
	
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = _current_profile.hitbox_size
	
	_hitbox_shape.shape = shape
	
	# Lógica de orientação centralizada e agora correta
	_hitbox.position = _current_profile.hitbox_position
	_hitbox.position.x *= _owner_node.facing_sign
	_hitbox.scale.x = _owner_node.facing_sign
	
	_hitbox_shape.set_deferred("disabled", false)
