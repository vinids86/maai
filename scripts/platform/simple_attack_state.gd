class_name SimpleAttackState
extends SimpleState

## Ponto opcional de onde o projétil será instanciado.
## Se não definido, usa a posição global do inimigo.
@export var projectile_spawn_point: Marker2D

enum Phases { STARTUP, ACTIVE, RECOVERY }
var _current_phase: Phases = Phases.STARTUP
var _time_left: float = 0.0
var _profile: AttackProfile

var _attack_direction: float = 1.0

func enter(_args: Dictionary = {}):
	_profile = owner_node.get_attack_profile()
	
	if not _profile:
		push_warning("SimpleAttackState: Inimigo sem AttackProfile configurado.")
		state_machine.on_current_state_finished({"outcome": "ATTACK_FINISHED"})
		return
	
	_attack_direction = owner_node.get_facing_direction()
	
	_change_phase(Phases.STARTUP)

func process_physics(delta: float) -> Vector2:
	if not _profile:
		return Vector2.ZERO
		
	if _current_phase == Phases.STARTUP:
		var target = GameManager.player_node
		
		if is_instance_valid(target):
			owner_node.face_position(target.global_position.x)
			_attack_direction = owner_node.get_facing_direction()
	
	_time_left -= delta
	
	if _time_left <= 0:
		_advance_phase()
	
	var move_velocity = Vector2.ZERO
	match _current_phase:
		Phases.STARTUP:
			move_velocity = _profile.startup_movement_velocity
		Phases.ACTIVE:
			move_velocity = _profile.active_movement_velocity
		Phases.RECOVERY:
			move_velocity = _profile.recovery_movement_velocity
			
	var final_velocity_x = move_velocity.x * _attack_direction
	
	var final_velocity_y = owner_node.velocity.y
	if not owner_node.is_on_floor():
		final_velocity_y += 980.0 * delta
		
	return Vector2(final_velocity_x, final_velocity_y)

func _advance_phase():
	match _current_phase:
		Phases.STARTUP:
			_change_phase(Phases.ACTIVE)
		Phases.ACTIVE:
			_change_phase(Phases.RECOVERY)
		Phases.RECOVERY:
			state_machine.on_current_state_finished({"outcome": "ATTACK_FINISHED"})

func _change_phase(new_phase: Phases):
	_current_phase = new_phase
	
	var duration = 0.0
	var sfx: AudioStream
	var anim_name: StringName = &""
	
	match _current_phase:
		Phases.STARTUP:
			duration = _profile.startup_duration
			sfx = _profile.startup_sfx
			anim_name = _profile.animation_name 
			
		Phases.ACTIVE:
			duration = _profile.active_duration
			sfx = _profile.active_sfx
			
			if _profile.projectile_scene:
				_spawn_projectile()
			
		Phases.RECOVERY:
			duration = _profile.recovery_duration
			sfx = _profile.recovery_sfx
			
	_time_left = duration
	
	state_machine.emit_phase_change({
		"state": "SimpleAttackState",
		"phase": Phases.keys()[_current_phase],
		"profile": _profile,
		"animation_to_play": anim_name,
		"sfx_to_play": sfx
	})

func _spawn_projectile() -> void:
	var scene = _profile.projectile_scene
	var projectile = scene.instantiate() as Projectile
	
	if not projectile:
		push_error("SimpleAttackState: Cena configurada não é um Projectile válido.")
		return

	var target = GameManager.player_node
	
	if is_instance_valid(target):
		var dir_to_target = sign(target.global_position.x - owner_node.global_position.x)
		if dir_to_target != 0:
			_attack_direction = dir_to_target
			owner_node.set_facing_direction(_attack_direction)

	var spawn_pos = owner_node.global_position
	
	if projectile_spawn_point:
		var relative_pos = owner_node.to_local(projectile_spawn_point.global_position)
		relative_pos.x = abs(relative_pos.x) * _attack_direction
		spawn_pos = owner_node.to_global(relative_pos)
	
	elif _profile.hitbox_position != Vector2.ZERO:
		var offset = _profile.hitbox_position
		offset.x = abs(offset.x) * _attack_direction
		spawn_pos = owner_node.to_global(offset)

	var shoot_dir = Vector2.RIGHT
	shoot_dir.x = _attack_direction

	get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_pos
	
	projectile.setup(owner_node, _profile, shoot_dir)
