class_name AIController
extends Node

# --- ESTRUTURA DE SEQUÊNCIAS DE COMPORTAMENTO (FASES) ---
var behavior_sequences: Dictionary = {
	"phase_1": [ # > 50% de vida (Sequência A)
		{ "defense": "parry" },
		{ "defense": "block" },
		{ "defense": "block" },
		{ "defense": "parry" },
		{ "defense": "block" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "normal_attack" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "normal_attack" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "skill_x" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "normal_attack" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "skill_y" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "normal_attack" },
		{ "defense": "parry", "riposte": "skill_a" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "skill_b" },
		{ "defense": "block" },
	],
	"phase_2": [ # <= 50% de vida (Sequência B - mais agressiva)
		{ "defense": "parry" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "normal_attack" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "skill_x" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "normal_attack" },
		{ "defense": "parry", "riposte": "skill_y" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "normal_attack" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "skill_b" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "skill_y" },
		{ "defense": "parry", "riposte": "skill_a" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "normal_attack" },
	]
}
# --- Variáveis de Controle ---
var _rng: RandomNumberGenerator
var _owner_actor: Node
@onready var _state_machine: StateMachine = get_parent().find_child("StateMachine")
@onready var _detection_area: Area2D = get_parent().find_child("DetectionArea")
@onready var _facing_component: FacingComponent = get_parent().find_child("FacingComponent")
var _health_component: HealthComponent
var _current_behavior_sequence: Array = []
var _current_phase: String = ""
var _behavior_sequence_counter: int = 0
var _pending_riposte_action: String = ""
var _is_in_attack_loop: bool = false
var _player_last_health: float = -1.0

func _ready():
	_owner_actor = get_parent()
	assert(_owner_actor != null, "AIController deve ser filho de um nó de ator.")
	assert(_state_machine != null, "AIController: StateMachine não encontrada no Inimigo.")
	assert(_detection_area != null, "AIController: Nó 'DetectionArea' não encontrado no Inimigo.")
	assert(_facing_component != null, "AIController: Nó 'FacingComponent' não encontrado no Inimigo.")

	_rng = RandomNumberGenerator.new()
	_rng.randomize()

	# Conecta-se aos sinais do próprio inimigo
	_state_machine.phase_changed.connect(_on_phase_changed)
	_detection_area.body_entered.connect(_on_player_entered_detection_area)
	_detection_area.body_exited.connect(_on_player_exited_detection_area)

	# --- LÓGICA DE FASE (VIDA DO INIMIGO) ---
	_health_component = _owner_actor.find_child("HealthComponent")
	assert(_health_component != null, "AIController: HealthComponent não encontrado no Inimigo.")
	_health_component.health_changed.connect(_on_owner_health_changed)
	_on_owner_health_changed(_health_component.current_health, _health_component.max_health)
	
	# --- LÓGICA DE OBSERVAÇÃO DO PLAYER ---
	await get_tree().process_frame
	
	if is_instance_valid(GameManager.player_node):
		var player_health_comp = GameManager.player_node.find_child("HealthComponent")
		if player_health_comp:
			player_health_comp.health_changed.connect(_on_player_health_changed)
			_player_last_health = player_health_comp.current_health
		else:
			push_warning("AIController: Player sem HealthComponent. Reset da IA não funcionará.")

		var player_state_machine = GameManager.player_node.find_child("StateMachine")
		if player_state_machine:
			player_state_machine.phase_changed.connect(_on_player_phase_changed)
		else:
			push_warning("AIController: Player sem StateMachine. Lógica de Finisher não funcionará.")
	else:
		push_warning("AIController: GameManager.player_node não é válido.")

# --- CONTROLE DE COMPORTAMENTO ---

func on_incoming_attack(_attacker: CharacterBody2D, _hitbox: Hitbox):
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

# --- HANDLERS DE SINAIS ---

func _on_phase_changed(phase_data: Dictionary):
	var state_name = phase_data.get("state_name")
	var phase_name = phase_data.get("phase_name")

	# --- NOVA REGRA: Reset quando a guarda do INIMIGO é quebrada ---
	# Se a IA entrar no seu próprio estado de guarda quebrada, a sequência reinicia.
	if state_name == "GuardBrokenState":
		reset_behavior_sequence()
		return

	# --- Lógica de Interrupção do Loop Unificada ---
	if (state_name in ["StaggerState", "BlockStunState", "ParriedState"]) and _is_in_attack_loop:
		_advance_sequence()
		return

	# Continua o loop de ataque se o ataque anterior terminou e não foi interrompido.
	if state_name == "AttackState" and phase_name == "RECOVERY" and _is_in_attack_loop:
		await get_tree().process_frame 
		_execute_normal_attack()
		return
	
	# Inicia um riposte (que pode ou não ser um loop) após um parry bem-sucedido.
	if state_name == "ParryState" and phase_name == "SUCCESS":
		if not _pending_riposte_action.is_empty():
			await get_tree().process_frame
			if _pending_riposte_action == "normal_attack":
				_is_in_attack_loop = true
			
			_execute_riposte_action(_pending_riposte_action)
			_pending_riposte_action = ""
			
			if not _is_in_attack_loop:
				_advance_sequence()

# --- HANDLER PARA O ESTADO DO PLAYER ---
func _on_player_phase_changed(phase_data: Dictionary):
	var player_state_name = phase_data.get("state_name")
	
	if player_state_name == "GuardBrokenState":
		await get_tree().process_frame
		_execute_normal_attack()


# --- FUNÇÕES AUXILIARES ---

func _on_owner_health_changed(current_health: float, max_health: float):
	var health_percentage: float = current_health / max_health
	var new_phase = "phase_1" if health_percentage > 0.5 else "phase_2"
		
	if new_phase != _current_phase:
		_set_behavior_phase(new_phase)

func _on_player_health_changed(current_health: float, _max_health: float):
	if current_health < _player_last_health:
		reset_behavior_sequence()
	_player_last_health = current_health

func _set_behavior_phase(phase_name: String):
	if not behavior_sequences.has(phase_name):
		push_error("AIController: Fase de comportamento desconhecida: %s" % phase_name)
		return
	_current_phase = phase_name
	_current_behavior_sequence = behavior_sequences.get(phase_name)
	reset_behavior_sequence()

func reset_behavior_sequence():
	_behavior_sequence_counter = 0
	_pending_riposte_action = ""
	_is_in_attack_loop = false

func _advance_sequence():
	_is_in_attack_loop = false
	_behavior_sequence_counter = (_behavior_sequence_counter + 1) % _current_behavior_sequence.size()

func _execute_riposte_action(action_to_execute: String):
	if action_to_execute == "normal_attack":
		_execute_normal_attack()
	else:
		_execute_skill(action_to_execute)

func _execute_skill(action_name: String):
	var skill_to_use: BaseSkill = _owner_actor.get_skill(action_name)
	if not skill_to_use:
		push_warning("AI: Skill '%s' não encontrada, usando ataque normal." % action_name)
		_execute_normal_attack()
		return
	skill_to_use.execute(_owner_actor, _state_machine)

func _execute_normal_attack():
	var combo_component = _owner_actor.find_child("ComboComponent")
	if combo_component:
		var profile = combo_component.get_next_attack_profile()
		if profile:
			_state_machine.on_attack_pressed(profile)

# --- Funções de Detecção e Debug ---
func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("debug_reset_ai"):
		reset_behavior_sequence()

func _on_player_entered_detection_area(body: Node2D):
	if body == GameManager.player_node:
		_facing_component.enable(body)
		reset_behavior_sequence()

func _on_player_exited_detection_area(body: Node2D):
	if body == GameManager.player_node:
		_facing_component.disable()
		reset_behavior_sequence()

func get_walk_direction() -> float: return 0.0
func is_running() -> bool: return false
