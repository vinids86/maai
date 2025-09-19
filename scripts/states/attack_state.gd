class_name AttackState
extends State

var hitbox: Area2D
var hitbox_shape: CollisionShape2D

var current_profile: AttackProfile

enum Phases { STARTUP, ACTIVE, RECOVERY, LINK }
var current_phase: Phases
var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}) -> void:
	if not hitbox:
		hitbox = owner_node.find_child("AttackHitbox") as Area2D
		if hitbox:
			hitbox_shape = hitbox.find_child("CollisionShape2D") as CollisionShape2D
		
		assert(hitbox != null, "AttackState: Nó 'AttackHitbox' não encontrado como filho do ator.")
		assert(hitbox_shape != null, "AttackState: Nó 'CollisionShape2D' não encontrado como filho da AttackHitbox.")

	self.current_profile = args.get("profile")

	if not current_profile:
		state_machine.on_current_state_finished()
		return
	
	owner_node.facing_locked = true
	_change_phase(Phases.STARTUP)

func exit() -> void:
	if hitbox_shape:
		hitbox_shape.disabled = true
		hitbox_shape.shape = null
	owner_node.facing_locked = false

func process_physics(delta: float, walk_direction: float, is_running: bool) -> void:
	if not current_profile:
		return

	time_left_in_phase -= delta
	
	if time_left_in_phase <= 0.0:
		var time_exceeded: float = -time_left_in_phase
		match current_phase:
			Phases.STARTUP:
				_change_phase(Phases.ACTIVE)
				time_left_in_phase -= time_exceeded
			Phases.ACTIVE:
				_change_phase(Phases.RECOVERY)
				time_left_in_phase -= time_exceeded
			Phases.RECOVERY:
				if state_machine.buffer_component.has_buffer():
					state_machine.on_current_state_finished()
					return
				else:
					_change_phase(Phases.LINK)
					time_left_in_phase -= time_exceeded
			Phases.LINK:
				state_machine.on_current_state_finished()
				return
	
	if current_phase == Phases.STARTUP or current_phase == Phases.ACTIVE:
		var move_vel: Vector2 = current_profile.movement_velocity
		owner_node.velocity.x = move_vel.x * owner_node.facing_sign
		owner_node.velocity.y = move_vel.y
	else:
		owner_node.velocity = Vector2.ZERO

func resolve_contact(context: ContactContext) -> ContactResult:
	var result_for_attacker = ContactResult.new()
	var my_poise = get_current_poise()
	var incoming_poise_damage = context.attack_profile.poise_damage

	if incoming_poise_damage >= my_poise:
		context.defender_health_comp.take_damage(context.attack_profile.damage)
		state_machine.on_current_state_finished({"outcome": "POISE_BROKEN"})
		
		result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.NONE
		result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.POISE_BROKEN
	else:
		context.defender_health_comp.take_damage(context.attack_profile.damage)
		
		result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.TRADE_LOST
		result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.HIT

	return result_for_attacker

func get_current_poise() -> float:
	if not current_profile:
		return 0.0
	return current_profile.action_poise

func get_attack_profile() -> AttackProfile:
	return current_profile

func allow_reentry() -> bool:
	return true
	
func allow_attack() -> bool:
	return current_phase == Phases.LINK
	
func allow_parry() -> bool:
	return current_phase == Phases.LINK

func allow_dodge() -> bool:
	return current_phase == Phases.RECOVERY or current_phase == Phases.LINK

func _change_phase(new_phase: Phases) -> void:
	current_phase = new_phase
	
	var sfx_to_play: AudioStream
	match current_phase:
		Phases.STARTUP:
			time_left_in_phase = current_profile.startup_duration
			sfx_to_play = current_profile.startup_sfx
		Phases.ACTIVE:
			time_left_in_phase = current_profile.active_duration
			sfx_to_play = current_profile.active_sfx
			_update_and_enable_hitbox()
		Phases.RECOVERY:
			time_left_in_phase = current_profile.recovery_duration
			sfx_to_play = current_profile.recovery_sfx
			if hitbox_shape != null:
				hitbox_shape.disabled = true
				hitbox_shape.shape = null
		Phases.LINK:
			time_left_in_phase = current_profile.link_duration
			
	var phase_data: Dictionary = {
		"state_name": self.name,
		"phase_name": Phases.keys()[current_phase],
		"profile": current_profile,
		"sfx_to_play": sfx_to_play
	}
	
	if current_phase == Phases.STARTUP:
		phase_data["animation_to_play"] = current_profile.animation_name
	
	state_machine.emit_phase_change(phase_data)

func _update_and_enable_hitbox() -> void:
	hitbox.attack_profile = current_profile
	
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = current_profile.hitbox_size
	
	hitbox_shape.shape = shape
	hitbox.position = current_profile.hitbox_position
	
	hitbox.position.x *= owner_node.facing_sign
	
	hitbox_shape.disabled = false
