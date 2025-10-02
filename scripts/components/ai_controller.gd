class_name AIController
extends Node

@export_group("Behavioral Strategy")
# A parry_chance original não será mais usada para a lógica principal,
# mas pode ser mantida para referência ou outros cenários.
@export var parry_chance: float = 0.70
@export var riposte_action_name: String = "skill_x"

var _rng: RandomNumberGenerator
var _owner_actor: Node
@onready var _state_machine: StateMachine = get_parent().find_child("StateMachine")

@onready var _detection_area: Area2D = get_parent().find_child("DetectionArea")
@onready var _facing_component: FacingComponent = get_parent().find_child("FacingComponent")

# --- NOVO CONTADOR ---
# Esta variável irá rastrear quantos golpes o jogador acertou em sequência.
var _player_combo_hits_count: int = 0

func _ready():
	_owner_actor = get_parent()
	assert(_owner_actor != null, "AIController deve ser filho de um nó de ator.")
	assert(_detection_area != null, "AIController: Nó 'DetectionArea' (Area2D) não encontrado no Inimigo.")
	assert(_facing_component != null, "AIController: Nó 'FacingComponent' não encontrado no Inimigo.")

	_detection_area.body_entered.connect(_on_player_entered_detection_area)
	_detection_area.body_exited.connect(_on_player_exited_detection_area)

	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	if _state_machine:
		_state_machine.phase_changed.connect(_on_phase_changed)

func _on_player_entered_detection_area(body: Node2D):
	if body.is_in_group("player"):
		_facing_component.enable(body)

func _on_player_exited_detection_area(body: Node2D):
	if body.is_in_group("player"):
		_facing_component.disable()

func get_walk_direction() -> float:
	return 0.0

func is_running() -> bool:
	return false

# --- LÓGICA DE PARRY ATUALIZADA ---
func on_incoming_attack(_attacker: CharacterBody2D, _hitbox: Hitbox):
	# Incrementa o contador a cada golpe recebido.
	_player_combo_hits_count += 1
	
	var do_parry: bool = false
	
	# Decide a chance de parry com base no número do golpe na sequência.
	match _player_combo_hits_count:
		1:
			# Primeiro golpe: nunca dá parry.
			do_parry = false
		2:
			# Segundo golpe: 60% de chance de parry.
			do_parry = _rng.randf() < 0.60
		3:
			# Terceiro golpe: 100% de chance de parry.
			do_parry = true

	if do_parry and _state_machine != null:
		var profile = _owner_actor.get_parry_profile()
		if profile:
			_state_machine.on_parry_pressed(profile)
			# Se o parry for bem-sucedido, reseta o contador para o próximo combo.
			_player_combo_hits_count = 0
	
	# Se o terceiro golpe não for um parry (por algum motivo) ou
	# se quisermos um ciclo de 3 golpes, resetamos o contador aqui.
	if _player_combo_hits_count >= 3:
		_player_combo_hits_count = 0

func _on_phase_changed(phase_data: Dictionary):
	if phase_data.get("state_name") == "ParryState" and phase_data.get("phase_name") == "SUCCESS":
		await get_tree().process_frame
		_decide_and_execute_action()

# --- LÓGICA DE DECISÃO PÓS-PARRY ATUALIZADA ---
func _decide_and_execute_action():
	# Rola um "dado" de 0.0 a 1.0 para determinar a ação com base em pesos.
	var roll: float = _rng.randf()

	if roll < 0.60: # 60% de chance
		_execute_normal_attack()
	elif roll < 0.80: # 20% de chance (de 0.60 a 0.80)
		# Tenta executar skill_x, se não existir, usa um ataque normal como fallback.
		if _owner_actor.has_method("get_skill") and _owner_actor.get_skill("skill_x"):
			_execute_skill("skill_x")
		else:
			_execute_normal_attack()
	elif roll < 0.90: # 10% de chance (de 0.80 a 0.90)
		if _owner_actor.has_method("get_skill") and _owner_actor.get_skill("skill_y"):
			_execute_skill("skill_y")
		else:
			_execute_normal_attack()
	else: # 10% de chance restantes (de 0.90 a 1.0)
		if _owner_actor.has_method("get_skill") and _owner_actor.get_skill("skill_a"):
			_execute_skill("skill_a")
		else:
			_execute_normal_attack()

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
