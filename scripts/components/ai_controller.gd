class_name AIController
extends Node

# --- ROTEIRO DE COMPORTAMENTO UNIFICADO ---
# (O seu roteiro completo permanece aqui, omitido por brevidade)
var behavior_sequence: Array[Dictionary] = [
	# --- Fase 1: Abertura (ritmo leve, leitura clara) ---
	{ "defense": "block" },
	{ "defense": "parry", "riposte": "normal_attack" },
	{ "defense": "block" },
	{ "defense": "parry", "riposte": "normal_attack" },

	# --- Fase 2: Aquecimento (introduz a primeira skill) ---
	{ "defense": "block" },
	{ "defense": "parry", "riposte": "normal_attack" },
	{ "defense": "block" },
	{ "defense": "parry", "riposte": "skill_x" },

	# --- Fase 3: Escalada (skill_y entra em cena) ---
	{ "defense": "block" },
	{ "defense": "parry", "riposte": "normal_attack" },
	{ "defense": "block" },
	{ "defense": "parry", "riposte": "skill_y" },

	# --- Fase 4: Pré-clímax (aproxima as skills) ---
	{ "defense": "block" },
	{ "defense": "parry", "riposte": "normal_attack" },
	{ "defense": "parry", "riposte": "skill_x" },

	# --- Fase 5: Ápice (Skill_Y → Skill_A → Janela de finalização) ---
	{ "defense": "block" },
	{ "defense": "parry", "riposte": "skill_y" },
	{ "defense": "parry", "riposte": "skill_a" }, # termina com o thrust não-parryável
	{ "defense": "block" }, # respiro / janela de punição do player
	{ "defense": "parry", "riposte": "normal_attack" }, # encerramento neutro (opcional)
]

# --------------------------------

var _rng: RandomNumberGenerator
var _owner_actor: Node
@onready var _state_machine: StateMachine = get_parent().find_child("StateMachine")
@onready var _detection_area: Area2D = get_parent().find_child("DetectionArea")
@onready var _facing_component: FacingComponent = get_parent().find_child("FacingComponent")

var _behavior_sequence_counter: int = 0
var _pending_riposte_action: String = ""


# --- NOVO CÓDIGO PARA DEBUG ---
func _unhandled_input(event: InputEvent) -> void:
	# Verifica se a ação "debug_reset_ai" foi pressionada.
	if event.is_action_pressed("debug_reset_ai"):
		reset_behavior_sequence()

func reset_behavior_sequence() -> void:
	print("AI sequence reset to 0.")
	_behavior_sequence_counter = 0
	_pending_riposte_action = ""
# ---------------------------------


func _ready():
	_owner_actor = get_parent()
	assert(_owner_actor != null, "AIController deve ser filho de um nó de ator.")
	assert(_detection_area != null, "AIController: Nó 'DetectionArea' (Area2D) não encontrado no Inimigo.")
	assert(_facing_component != null, "AIController: Nó 'FacingComponent' não encontrado no Inimigo.")

	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	if _state_machine:
		_state_machine.phase_changed.connect(_on_phase_changed)
	
	_detection_area.body_entered.connect(_on_player_entered_detection_area)
	_detection_area.body_exited.connect(_on_player_exited_detection_area)

func _on_player_entered_detection_area(body: Node2D):
	if body == GameManager.player_node:
		_facing_component.enable(body)
		reset_behavior_sequence()

func _on_player_exited_detection_area(body: Node2D):
	if body == GameManager.player_node:
		_facing_component.disable()
		reset_behavior_sequence()

func get_walk_direction() -> float:
	return 0.0

func is_running() -> bool:
	return false

func on_incoming_attack(_attacker: CharacterBody2D, _hitbox: Hitbox):
	if behavior_sequence.is_empty():
		return

	_pending_riposte_action = ""

	# 1. Decide qual ação defensiva tomar com base no roteiro unificado.
	var current_step = behavior_sequence[_behavior_sequence_counter]
	var defense_action = current_step.get("defense", "block")

	if defense_action == "parry":
		var profile = _owner_actor.get_parry_profile()
		if profile:
			# Guarda qual contra-ataque deve ser usado se o parry for bem-sucedido.
			_pending_riposte_action = current_step.get("riposte", "normal_attack")
			_state_machine.on_parry_pressed(profile)
	# Se a ação for "block", nada acontece, e o inimigo recebe o golpe.

	# 2. Avança para a próxima ação no roteiro.
	_behavior_sequence_counter = (_behavior_sequence_counter + 1) % behavior_sequence.size()

func _on_phase_changed(phase_data: Dictionary):
	if phase_data.get("state_name") == "ParryState" and phase_data.get("phase_name") == "SUCCESS":
		if not _pending_riposte_action.is_empty():
			await get_tree().process_frame
			_execute_riposte_action(_pending_riposte_action)
			_pending_riposte_action = "" # Limpa a ação pendente após o uso.

func _execute_riposte_action(action_to_execute: String):
	if action_to_execute == "normal_attack":
		_execute_normal_attack()
	else:
		# Assume que qualquer outra string é o nome de uma skill.
		_execute_skill(action_to_execute)

func _execute_skill(action_name: String):
	var skill_to_use: BaseSkill = _owner_actor.get_skill(action_name)
	
	if not skill_to_use:
		_execute_normal_attack()
		return
	
	skill_to_use.execute(_owner_actor, _state_machine)

func _execute_normal_attack():
	var combo_component = _owner_actor.find_child("ComboComponent")
	if combo_component:
		var profile = combo_component.get_next_attack_profile()
		if profile:
			_state_machine.on_attack_pressed(profile)
