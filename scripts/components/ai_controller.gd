class_name AIController
extends Node

enum BehaviorID {
	ENEMY_INTRO_1,
	ENEMY_INTRO_2,
	ENEMY_INTRO_3,
	ENEMY_MID_1,
	ENEMY_MID_2,
	ENEMY_ADV_1,
	ENEMY_ADV_2,
	ENEMY_ELITE_1,
	ENEMY_ELITE_2,
	BOSS_DEFAULT,
}

@export var behavior_id: BehaviorID = BehaviorID.ENEMY_INTRO_1

const ALL_BEHAVIORS = {
	BehaviorID.ENEMY_INTRO_1: {
		"phase_1": [
			{ "defense": "parry" }, { "defense": "block" }, { "defense": "parry", "riposte": "skill_z" }, { "defense": "block" },
			{ "defense": "parry" }, { "defense": "parry" }, { "defense": "block" }, { "defense": "block" }
		],
		"phase_2": [
			{ "defense": "block" }, { "defense": "parry" }, { "defense": "block" }, { "defense": "block" },
			{ "defense": "parry" }, { "defense": "block" }, { "defense": "block" }, { "defense": "parry" }
		]
	},
	BehaviorID.ENEMY_INTRO_2: {
		"phase_1": [
			{ "defense": "parry" }, { "defense": "block" }, { "defense": "block" }, { "defense": "parry" },
			{ "defense": "block" }, { "defense": "block" }, { "defense": "parry" }, { "defense": "block" }
		],
		"phase_2": [
			{ "defense": "parry" }, { "defense": "block" }, { "defense": "parry" }, { "defense": "block" },
			{ "defense": "parry" }, { "defense": "block" }, { "defense": "parry" }, { "defense": "block" }
		]
	},
	BehaviorID.ENEMY_INTRO_3: {
		"phase_1": [
			{ "defense": "block" }, { "defense": "parry" }, { "defense": "block" }, { "defense": "parry" },
			{ "defense": "block" }, { "defense": "parry" }, { "defense": "block" }, { "defense": "parry" }
		],
		"phase_2": [
			{ "defense": "parry" }, { "defense": "parry" }, { "defense": "block" }, { "defense": "parry" },
			{ "defense": "block" }, { "defense": "parry" }, { "defense": "block" }, { "defense": "parry" },
			{ "defense": "block" }, { "defense": "block" }
		]
	},
	BehaviorID.ENEMY_MID_1: {
		"phase_1": [
			{ "defense": "parry" }, { "defense": "block" }, { "defense": "parry" }, { "defense": "block" },
			{ "defense": "block" }, { "defense": "parry", "riposte": "skill_x" }, { "defense": "block" }, { "defense": "parry" }
		],
		"phase_2": [
			{ "defense": "block" }, { "defense": "parry", "riposte": "skill_x" }, { "defense": "block" }, { "defense": "parry" },
			{ "defense": "block" }, { "defense": "parry", "riposte": "skill_x" }, { "defense": "block" }, { "defense": "parry" }
		]
	},
	BehaviorID.ENEMY_MID_2: {
		"phase_1": [
			{ "defense": "block" }, { "defense": "parry" }, { "defense": "block" }, { "defense": "parry", "riposte": "skill_x" },
			{ "defense": "block" }, { "defense": "block" }, { "defense": "parry" }, { "defense": "block" }
		],
		"phase_2": [
			{ "defense": "parry", "riposte": "skill_x" }, { "defense": "block" }, { "defense": "parry" }, { "defense": "parry", "riposte": "skill_x" },
			{ "defense": "block" }, { "defense": "block" }, { "defense": "parry" }, { "defense": "block" }
		]
	},
	BehaviorID.ENEMY_ADV_1: {
		"phase_1": [
			{ "defense": "parry" }, { "defense": "block" }, { "defense": "parry", "riposte": "skill_y" }, { "defense": "block" },
			{ "defense": "parry" }, { "defense": "block" }, { "defense": "parry" }, { "defense": "block" }
		],
		"phase_2": [
			{ "defense": "block" }, { "defense": "parry", "riposte": "skill_y" }, { "defense": "block" }, { "defense": "parry" },
			{ "defense": "block" }, { "defense": "parry", "riposte": "skill_y" }, { "defense": "block" }, { "defense": "parry" }
		]
	},
	BehaviorID.ENEMY_ADV_2: {
		"phase_1": [
			{ "defense": "block" }, { "defense": "parry" }, { "defense": "block" }, { "defense": "parry", "riposte": "skill_y" },
			{ "defense": "block" }, { "defense": "parry" }, { "defense": "block" }, { "defense": "block" }
		],
		"phase_2": [
			{ "defense": "parry", "riposte": "skill_y" }, { "defense": "block" }, { "defense": "parry" }, { "defense": "parry", "riposte": "skill_y" },
			{ "defense": "block" }, { "defense": "block" }, { "defense": "parry" }, { "defense": "block" }
		]
	},
	BehaviorID.ENEMY_ELITE_1: {
		"phase_1": [
			{ "defense": "parry" }, { "defense": "block" }, { "defense": "parry", "riposte": "skill_a" }, { "defense": "block" },
			{ "defense": "block" }, { "defense": "parry" }, { "defense": "block" }, { "defense": "parry" }
		],
		"phase_2": [
			{ "defense": "block" }, { "defense": "parry", "riposte": "skill_a" }, { "defense": "block" }, { "defense": "parry" },
			{ "defense": "block" }, { "defense": "parry", "riposte": "skill_a" }, { "defense": "block" }, { "defense": "parry" }
		]
	},
	BehaviorID.ENEMY_ELITE_2: {
		"phase_1": [
			{ "defense": "block" }, { "defense": "parry" }, { "defense": "block" }, { "defense": "parry", "riposte": "skill_a" },
			{ "defense": "block" }, { "defense": "block" }, { "defense": "parry" }, { "defense": "block" }
		],
		"phase_2": [
			{ "defense": "parry", "riposte": "skill_a" }, { "defense": "block" }, { "defense": "parry" }, { "defense": "parry", "riposte": "skill_a" },
			{ "defense": "block" }, { "defense": "block" }, { "defense": "parry" }, { "defense": "block" }
		]
	},
	BehaviorID.BOSS_DEFAULT: {
		"phase_1": [
			{ "defense": "parry", "riposte": "normal_attack" }, { "defense": "block" }, { "defense": "block" },
			{ "defense": "parry", "riposte": "normal_attack" }, { "defense": "block" }, { "defense": "parry", "riposte": "normal_attack" },
			{ "defense": "block" }, { "defense": "block" }, { "defense": "parry", "riposte": "skill_x" }, { "defense": "block" },
			{ "defense": "parry", "riposte": "normal_attack" }, { "defense": "block" }, { "defense": "parry", "riposte": "skill_y" },
			{ "defense": "block" }, { "defense": "parry", "riposte": "normal_attack" }, { "defense": "parry", "riposte": "skill_a" },
			{ "defense": "block" }, { "defense": "parry", "riposte": "skill_b" }, { "defense": "block" }
		],
		"phase_2": [
			{ "defense": "parry" }, { "defense": "block" }, { "defense": "parry", "riposte": "normal_attack" }, { "defense": "block" },
			{ "defense": "parry", "riposte": "skill_x" }, { "defense": "block" }, { "defense": "parry", "riposte": "normal_attack" },
			{ "defense": "parry", "riposte": "skill_y" }, { "defense": "block" }, { "defense": "parry", "riposte": "normal_attack" },
			{ "defense": "block" }, { "defense": "parry", "riposte": "skill_b" }, { "defense": "block" }, { "defense": "parry", "riposte": "skill_y" },
			{ "defense": "parry", "riposte": "skill_a" }, { "defense": "block" }, { "defense": "parry", "riposte": "normal_attack" }
		]
	}
}

var _rng: RandomNumberGenerator
var _owner_actor: Node
@onready var _state_machine: StateMachine = get_parent().find_child("StateMachine")
@onready var _detection_area: Area2D = get_parent().find_child("DetectionArea")
@onready var _facing_component: FacingComponent = get_parent().find_child("FacingComponent")
@onready var _combo_chain_timer: Timer = find_child("ComboChainTimer")
var _health_component: HealthComponent

var _selected_behavior_data: Dictionary = {}
var _current_behavior_sequence: Array = []

var _current_phase: String = ""
var _behavior_sequence_counter: int = 0
var _pending_riposte_action: String = ""
var _is_in_attack_loop: bool = false
var _player_last_health: float = -1.0

# --- CONFIGURAÇÃO DE PERSEGUIÇÃO E COMBATE ---
var _current_target: Node2D = null
@export_group("Movement Settings")
@export var stop_distance: float = 200.0 
@export var run_distance: float = 400.0

@export_group("Combat Initiation Settings")
## Distância para considerar iniciar um ataque (geralmente similar ou um pouco maior que o alcance do ataque).
@export var engage_range: float = 210.0
## Tempo mínimo entre ataques iniciados pelo inimigo.
@export var min_attack_cooldown: float = 1.5
## Tempo máximo entre ataques iniciados pelo inimigo.
@export var max_attack_cooldown: float = 3.0
## Tempo de reação ("hesitação") antes de atacar quando entra no range.
@export var reaction_delay: float = 0.3
## Ataque padrão a ser usado para validar se o inimigo pode atacar. 
## (Nota: O ataque real será puxado do ComboComponent para manter a sequência)
@export var default_attack_profile: AttackProfile

# Variáveis de Controle de Ataque
var _cooldown_timer: float = 0.0
var _reaction_timer: float = 0.0
var _is_preparing_attack: bool = false

func _ready():
	_owner_actor = get_parent()
	assert(_owner_actor != null, "AIController must be a child of an actor node.")
	
	if not ALL_BEHAVIORS.has(behavior_id):
		push_error("AIController: BehaviorID '%s' selecionado não existe no banco de dados ALL_BEHAVIORS." % behavior_id)
		return
	_selected_behavior_data = ALL_BEHAVIORS[behavior_id]
	
	assert(_state_machine != null, "AIController: StateMachine not found in Enemy.")
	assert(_detection_area != null, "AIController: Node 'DetectionArea' not found in Enemy.")
	assert(_facing_component != null, "AIController: Node 'FacingComponent' not found in Enemy.")
	assert(_combo_chain_timer != null, "AIController: Node 'ComboChainTimer' not found.")

	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	
	_reset_cooldown()

	_state_machine.phase_changed.connect(_on_phase_changed)
	
	if not _detection_area.body_entered.is_connected(_on_player_entered_detection_area):
		_detection_area.body_entered.connect(_on_player_entered_detection_area)
	if not _detection_area.body_exited.is_connected(_on_player_exited_detection_area):
		_detection_area.body_exited.connect(_on_player_exited_detection_area)
	
	await get_tree().process_frame
	var overlapping_bodies = _detection_area.get_overlapping_bodies()
	for body in overlapping_bodies:
		_check_and_set_target(body)

	_health_component = _owner_actor.find_child("HealthComponent")
	assert(_health_component != null, "AIController: HealthComponent not found in Enemy.")
	_health_component.health_changed.connect(_on_owner_health_changed)
	
	_on_owner_health_changed(_health_component.current_health, _health_component.max_health)

	if is_instance_valid(GameManager.player_node):
		var player_health_comp = GameManager.player_node.find_child("HealthComponent")
		if player_health_comp:
			player_health_comp.health_changed.connect(_on_player_health_changed)
			_player_last_health = player_health_comp.current_health

		var player_state_machine = GameManager.player_node.find_child("StateMachine")
		if player_state_machine:
			player_state_machine.transitioned.connect(func(f, t): _debug_log_player_state(f, t))
			player_state_machine.phase_changed.connect(_on_player_phase_changed)
	
	_state_machine.transitioned.connect(func(f, t): _debug_log_ai_state(f, t))
	_combo_chain_timer.timeout.connect(_on_ComboChainTimer_timeout)

func _physics_process(delta: float):
	if not is_instance_valid(_owner_actor) or not is_instance_valid(_current_target):
		return

	# Atualiza timers
	if _cooldown_timer > 0:
		_cooldown_timer -= delta
	
	if _is_preparing_attack:
		_reaction_timer -= delta

	var distance_to_target = _owner_actor.global_position.distance_to(_current_target.global_position)
	
	if distance_to_target <= engage_range:
		_handle_attack_opportunity(delta)
	else:
		_is_preparing_attack = false
		_reaction_timer = 0.0

func _handle_attack_opportunity(_delta: float):
	if _cooldown_timer <= 0:
		if not _is_preparing_attack:
			_is_preparing_attack = true
			_reaction_timer = reaction_delay
		elif _reaction_timer <= 0:
			_try_start_attack_loop()

func _try_start_attack_loop():
	# Segurança: Não inicia se já estiver atacando
	if _is_in_attack_loop:
		return 
	
	var current_state = _state_machine.current_state
	# Só ataca se estiver livre (Andando ou Parado)
	if not (current_state is LocomotionState): 
		return

	if not default_attack_profile:
		push_warning("AIController: Tentativa de ataque sem 'default_attack_profile' configurado.")
		_reset_cooldown()
		return

	# -- CORREÇÃO 1: Inicia o Loop de Ataque --
	_is_in_attack_loop = true
	
	# Reseta o ComboComponent para garantir que comece do primeiro golpe
	var combo_comp = _owner_actor.find_child("ComboComponent")
	if combo_comp and combo_comp.has_method("reset_combo"):
		combo_comp.reset_combo()
	
	# Chama a função que executa o ataque e agenda o próximo
	_execute_normal_attack()
	
	_is_preparing_attack = false
	_reset_cooldown()

func _reset_cooldown():
	_cooldown_timer = _rng.randf_range(min_attack_cooldown, max_attack_cooldown)
	_is_preparing_attack = false

func _debug_log_player_state(f: State, t: State):
	pass

func _debug_log_ai_state(f: State, t: State):
	pass

# --- LÓGICA DE MOVIMENTO ---

func get_walk_direction() -> float:
	if not _current_target or not is_instance_valid(_current_target):
		return 0.0
	
	var my_pos_x = _owner_actor.global_position.x
	var target_pos_x = _current_target.global_position.x
	var distance_x = abs(target_pos_x - my_pos_x)
	
	if distance_x > stop_distance:
		return sign(target_pos_x - my_pos_x)
	
	return 0.0

func is_running() -> bool:
	if not _current_target or not is_instance_valid(_current_target):
		return false
		
	var distance_x = abs(_current_target.global_position.x - _owner_actor.global_position.x)
	return distance_x > run_distance

# --- DETECÇÃO DO PLAYER ---

func _check_and_set_target(body: Node2D):
	var is_player = false
	
	if body.name == "Player": is_player = true
	elif body.is_in_group("Player"): is_player = true
	elif body == GameManager.player_node: is_player = true
	
	if is_player:
		_current_target = body
		_facing_component.enable(body)
		return true
	return false

func _on_player_entered_detection_area(body: Node2D):
	_check_and_set_target(body)

func _on_player_exited_detection_area(body: Node2D):
	if body == _current_target:
		_current_target = null
		_facing_component.disable()
		_combo_chain_timer.stop()
		_is_preparing_attack = false 
		reset_behavior_sequence()

# --- COMBATE ---

func on_incoming_attack(_attacker: CharacterBody2D, _hitbox: Hitbox):
	# -- CORREÇÃO 2: Reset de Prioridade Defensiva --
	# Se o inimigo é atacado, ele perde a "concentração" do ataque proativo.
	# O cooldown é resetado para que ele foque em defender/reagir primeiro.
	_is_preparing_attack = false
	_reset_cooldown()
	
	if _current_behavior_sequence.is_empty(): return
	if _is_in_attack_loop: return

	_pending_riposte_action = ""
	var current_step = _current_behavior_sequence[_behavior_sequence_counter]
	var defense_action = current_step.get("defense", "block")

	if defense_action == "parry":
		var profile = _owner_actor.get_parry_profile()
		if profile:
			_pending_riposte_action = current_step.get("riposte", "normal_attack")
			_state_machine.on_parry_pressed(profile)
	else:
		_advance_sequence()

func _on_phase_changed(phase_data: Dictionary):
	var state_name = phase_data.get("state_name")
	var phase_name = phase_data.get("phase_name")

	# Se a defesa falhou (Guard Break) ou o player quebrou a postura, reseta tudo.
	if state_name == "GuardBrokenState":
		_combo_chain_timer.stop()
		_reset_cooldown() # Garante cooldown se for quebrado
		reset_behavior_sequence()
		return

	# Se entrou em estado de sofrer dano/blockstun, para o ataque proativo se houver
	if (state_name in ["StaggerState", "BlockStunState", "ParriedState"]):
		# -- CORREÇÃO 2 (Cont.): Reseta cooldown ao entrar em estados de reação --
		_reset_cooldown()
		
		if _is_in_attack_loop:
			_combo_chain_timer.stop()
			_advance_sequence()
		return

	if state_name == "ParryState" and phase_name == "SUCCESS":
		# Sucesso no Parry -> Riposte tem prioridade total
		if not _pending_riposte_action.is_empty():
			var action_to_take: String = _pending_riposte_action
			_pending_riposte_action = ""
			
			var combo_comp = _owner_actor.find_child("ComboComponent")
			if combo_comp and combo_comp.has_method("reset_combo"):
					combo_comp.reset_combo()

			_is_in_attack_loop = (action_to_take == "normal_attack")

			_execute_riposte_action(action_to_take)

		elif _pending_riposte_action.is_empty():
			_advance_sequence()

	if state_name == "FinisherReadyState":
		_combo_chain_timer.stop()
		_is_in_attack_loop = false
		var combo_comp = _owner_actor.find_child("ComboComponent")
		if combo_comp and combo_comp.has_method("reset_combo"):
			combo_comp.reset_combo()
		_execute_normal_attack()


func _on_player_phase_changed(phase_data: Dictionary):
	var player_state_name = phase_data.get("state_name")

	if player_state_name == "GuardBrokenState":
		if _is_in_attack_loop:
			return
		elif _state_machine.current_state is LocomotionState:
			_combo_chain_timer.stop()
			var combo_comp = _owner_actor.find_child("ComboComponent")
			if combo_comp and combo_comp.has_method("reset_combo"):
				combo_comp.reset_combo()
			_execute_normal_attack()


func _on_owner_health_changed(current_health: float, max_health: float):
	var health_percentage: float = current_health / max_health
	var new_phase = "phase_1" if health_percentage > 0.5 else "phase_2"
	if new_phase != _current_phase:
		_combo_chain_timer.stop()
		_set_behavior_phase(new_phase)

func _on_player_health_changed(current_health: float, _max_health: float):
	if _is_in_attack_loop:
		_player_last_health = current_health
		return
	if current_health < _player_last_health:
		_combo_chain_timer.stop()
		reset_behavior_sequence()
	_player_last_health = current_health

func _set_behavior_phase(phase_name: String):
	if not _selected_behavior_data.has(phase_name):
		push_error("AIController: Fase '%s' não encontrada no BehaviorID '%s'." % [phase_name, behavior_id])
		_current_behavior_sequence = []
	else:
		_current_behavior_sequence = _selected_behavior_data.get(phase_name)

	_current_phase = phase_name
	_combo_chain_timer.stop()
	reset_behavior_sequence()

func reset_behavior_sequence():
	_combo_chain_timer.stop()
	_behavior_sequence_counter = 0
	_pending_riposte_action = ""
	_is_in_attack_loop = false
	var combo_comp = _owner_actor.find_child("ComboComponent")
	if combo_comp and combo_comp.has_method("reset_combo"):
		combo_comp.reset_combo()


func _advance_sequence():
	_combo_chain_timer.stop()
	_is_in_attack_loop = false
	if _current_behavior_sequence and not _current_behavior_sequence.is_empty():
		_behavior_sequence_counter = (_behavior_sequence_counter + 1) % _current_behavior_sequence.size()
	else:
		_behavior_sequence_counter = 0
	var combo_comp = _owner_actor.find_child("ComboComponent")
	if combo_comp and combo_comp.has_method("reset_combo"):
		combo_comp.reset_combo()


func _execute_riposte_action(action_to_execute: String):
	if action_to_execute == "normal_attack":
		_execute_normal_attack()
	else:
		_is_in_attack_loop = false
		_combo_chain_timer.stop()
		_execute_skill(action_to_execute)
		_advance_sequence()


func _execute_skill(action_name: String):
	var skill_to_use: BaseSkill = _owner_actor.get_skill(action_name)
	if not skill_to_use:
		return
	skill_to_use.execute(_owner_actor, _state_machine)


func _execute_normal_attack():
	var combo_component = _owner_actor.find_child("ComboComponent")
	if combo_component:
		# Aqui o ComboComponent decide qual é o próximo golpe da cadeia
		var profile: AttackProfile = combo_component.get_next_attack_profile()

		if profile:
			_state_machine.on_attack_pressed(profile)

			if _is_in_attack_loop:
				# Calcula o tempo para o próximo golpe baseado na duração do atual
				var time_to_next_input = profile.startup_duration + profile.active_duration + profile.recovery_duration - 0.05

				if time_to_next_input > 0.0:
					_combo_chain_timer.start(time_to_next_input)
				else:
					_on_ComboChainTimer_timeout()
		else:
			# Acabou os ataques do combo? Para o loop.
			_combo_chain_timer.stop()
			if _is_in_attack_loop:
				_advance_sequence()


func _on_ComboChainTimer_timeout():
	if _is_in_attack_loop:
		_execute_normal_attack()


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("debug_reset_ai"):
		_combo_chain_timer.stop()
		reset_behavior_sequence()
