class_name LocomotionState
extends State

@export var locomotion_profile: LocomotionProfile

# O LocomotionState agora tem as suas próprias fases internas.
enum Phases { IDLE, WALK, RUN }
var current_phase: Phases = Phases.IDLE

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Ao entrar no estado, emitimos a nossa fase inicial.
func enter(args: Dictionary = {}):
	# Assumimos que o personagem começa parado.
	_change_phase(Phases.IDLE)


func process_physics(delta: float, is_running: bool = false):
	if not owner_node.is_on_floor():
		owner_node.velocity.y += gravity * delta

	if not locomotion_profile:
		push_warning("LocomotionState não tem um LocomotionProfile atribuído no Inspetor.")
		return

	var walk_direction = Input.get_axis("move_left", "move_right")
	
	_update_facing_sign(walk_direction)
	
	movement_component.calculate_walk_velocity(walk_direction, is_running, locomotion_profile)
	
	# Verificamos se a fase de locomoção mudou e emitimos o sinal se necessário.
	_update_and_emit_phase(is_running)


func process_input(event: InputEvent):
	pass


func allow_dodge() -> bool:
	return owner_node.is_on_floor()


# Este estado agora responde à pergunta específica "posso iniciar um ataque?".
func can_initiate_attack() -> bool:
	return owner_node.is_on_floor()


func _update_facing_sign(direction: float):
	if owner_node.facing_locked:
		return
		
	if direction > 0:
		owner_node.facing_sign = 1
	elif direction < 0:
		owner_node.facing_sign = -1


func _update_and_emit_phase(is_running: bool):
	var new_phase: Phases
	
	# Determinamos a nova fase com base na velocidade e no estado de corrida.
	if owner_node.velocity.x == 0:
		new_phase = Phases.IDLE
	elif is_running:
		new_phase = Phases.RUN
	else:
		new_phase = Phases.WALK
		
	if new_phase != current_phase:
		_change_phase(new_phase)


func _change_phase(new_phase: Phases):
	current_phase = new_phase
	
	var anim_to_play: StringName
	match current_phase:
		Phases.IDLE:
			anim_to_play = locomotion_profile.idle_animation
		Phases.WALK:
			anim_to_play = locomotion_profile.walk_animation
		Phases.RUN:
			anim_to_play = locomotion_profile.run_animation
	
	var phase_data = {
		"state_name": self.name,
		"phase_name": Phases.keys()[current_phase], # Converte o enum para String
		"profile": locomotion_profile,
		"animation_to_play": anim_to_play
	}
	
	state_machine.emit_phase_change(phase_data)
