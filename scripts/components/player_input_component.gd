class_name PlayerInputComponent
extends Node

# --- DEPENDÊNCIAS ---
var player: Player
var state_machine: StateMachine

# --- CONFIGURAÇÃO INTERNA ---
var hold_input_timer: Timer
var run_cancel_timer: Timer

const HOLD_TIME_THRESHOLD: float = 0.2
const RUN_CANCEL_TIME: float = 0.1

func setup(target_player: Player) -> void:
	player = target_player
	
	# Aguarda a state machine estar pronta se necessário, 
	# mas como chamamos no _ready do player, ela já deve existir.
	state_machine = player.state_machine
	
	_setup_timers()
	
	# Conexão de sinais
	if player.surface_contact_component:
		player.surface_contact_component.landed.connect(_on_landed)

func _setup_timers() -> void:
	# Criação via código continua sendo útil para não sujar a Scene Tree do editor
	# com timers que são puramente lógicos deste componente.
	hold_input_timer = Timer.new()
	hold_input_timer.wait_time = HOLD_TIME_THRESHOLD
	hold_input_timer.one_shot = true
	hold_input_timer.timeout.connect(_on_hold_input_timer_timeout)
	add_child(hold_input_timer)
	
	run_cancel_timer = Timer.new()
	run_cancel_timer.wait_time = RUN_CANCEL_TIME
	run_cancel_timer.one_shot = true
	run_cancel_timer.timeout.connect(_on_run_cancel_timer_timeout)
	add_child(run_cancel_timer)

func _unhandled_input(event: InputEvent) -> void:
	# Segurança crucial: Se setup() não foi chamado ainda, não processa nada.
	if not player or not is_instance_valid(player): return
	
	if event.is_action_pressed("jump"):
		var profile = player.running_jump_profile if player.is_running else player.get_jump_profile()
		if profile:
			state_machine.on_jump_pressed(profile)
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_released("jump"):
		state_machine.on_jump_released()
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed("dash_run"):
		_send_dash_intention()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("dodge"):
		_handle_dodge_press()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_released("dodge"):
		_handle_dodge_release()
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("attack"):
		_handle_attack_input()
		get_viewport().set_input_as_handled()
		return

	if Input.is_action_pressed("skill_modifier"):
		_handle_skill_input(event)
		return

	if event.is_action_pressed("parry"):
		var profile = player.get_parry_profile()
		if profile:
			state_machine.on_parry_pressed(profile)
		get_viewport().set_input_as_handled()
		return

	# Delegação genérica
	state_machine.process_input(event)

# --- MÉTODOS PRIVADOS DE LÓGICA ---

func _handle_dodge_press() -> void:
	if not player.is_on_floor():
		_send_dodge_intention()
	else:
		if not run_cancel_timer.is_stopped():
			run_cancel_timer.stop()
			_send_dodge_intention()
		else:
			hold_input_timer.start()

func _handle_dodge_release() -> void:
	if not player.is_running:
		if not hold_input_timer.is_stopped():
			hold_input_timer.stop()
			_send_dodge_intention()
	else:
		run_cancel_timer.start()

func _handle_attack_input() -> void:
	var profile_to_use: AttackProfile
	
	if player.is_on_floor():
		if player.combo_component:
			profile_to_use = player.combo_component.get_next_attack_profile()
	else:
		if player.air_combo_component:
			profile_to_use = player.air_combo_component.get_next_attack_profile()
	
	if profile_to_use:
		state_machine.on_attack_pressed(profile_to_use)

func _handle_skill_input(event: InputEvent) -> void:
	var skills = player.get_equipped_skills()
	for action_name in skills.keys():
		if event.is_action_pressed(action_name):
			var skill: BaseSkill = skills.get(action_name)
			if skill:
				skill.execute(player, state_machine)
			get_viewport().set_input_as_handled()
			return

func _handle_debug_vfx() -> void:
	if player.vfx_component:
		var spawn_pos = player.global_position + Vector2(30 * player.facing_sign, -15)
		var direction = Vector2.RIGHT * player.facing_sign
		player.vfx_component.spawn_vfx("blood_splatter", spawn_pos, direction)

func _on_hold_input_timer_timeout() -> void:
	if Input.is_action_pressed("dodge"):
		player.is_running = true
		player.sheath_weapon()

func _on_run_cancel_timer_timeout() -> void:
	player.is_running = false

func _on_landed() -> void:
	if Input.is_action_pressed("dodge"):
		if hold_input_timer.is_stopped():
			hold_input_timer.start()

func _send_dash_intention() -> void:
	var profile = player.get_dash_profile()
	if profile:
		state_machine.on_dash_pressed(profile)

func _send_dodge_intention() -> void:
	var direction = _get_dodge_direction_from_input()
	var profile = _get_dodge_profile_for_direction(direction)
	if profile:
		state_machine.on_dodge_pressed(direction, profile)

func _get_dodge_direction_from_input() -> Vector2:
	var direction = Vector2.ZERO
	if Input.is_action_pressed("move_up"): direction.y = -1
	elif Input.is_action_pressed("move_down"): direction.y = 1
	if Input.is_action_pressed("move_left"): direction.x = -1
	elif Input.is_action_pressed("move_right"): direction.x = 1
	return direction

func _get_dodge_profile_for_direction(direction: Vector2) -> DodgeProfile:
	if direction.y < 0: return player.up_dodge_profile
	elif direction.y > 0: return player.down_dodge_profile
	elif direction.x != 0:
		if direction.x * player.facing_sign > 0: return player.forward_dodge_profile
		else: return player.back_dodge_profile
	else: return player.neutral_dodge_profile
