class_name AIController
extends Node

@export_group("Behavioral Strategy")
@export var parry_chance: float = 0.70
@export var riposte_action_name: String = "skill_x"

var _rng: RandomNumberGenerator
var _owner_actor: Node
@onready var _state_machine: StateMachine = get_parent().find_child("StateMachine")

@onready var _detection_area: Area2D = get_parent().find_child("DetectionArea")
@onready var _facing_component: FacingComponent = get_parent().find_child("FacingComponent")

func _ready():
	_owner_actor = get_parent()
	assert(_owner_actor != null, "AIController deve ser filho de um nó de ator.")
	assert(_detection_area != null, "AIController: Nó 'DetectionArea' (Area2D) não encontrado no Inimigo.")
	assert(_facing_component != null, "AIController: Nó 'FacingComponent' não encontrado no Inimigo.")

	_detection_area.body_entered.connect(_on_player_entered_detection_area)
	_detection_area.body_exited.connect(_on_player_exited_detection_area)

	parry_chance = clampf(parry_chance, 0.0, 1.0)
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	if _state_machine:
		_state_machine.phase_changed.connect(_on_phase_changed)

func _on_player_entered_detection_area(body: Node2D):
	# Verifica se o corpo que entrou está no grupo "player".
	if body.is_in_group("player"):
		# Se for o jogador, LIGA o componente, passando o jogador como alvo.
		_facing_component.enable(body)
		# (No futuro, aqui você poderia transicionar a IA para um estado de combate)

func _on_player_exited_detection_area(body: Node2D):
	if body.is_in_group("player"):
		# Se for o jogador, DESLIGA o componente.
		_facing_component.disable()
		# (No futuro, aqui a IA poderia desistir da perseguição)

func get_walk_direction() -> float:
	return 0.0

func is_running() -> bool:
	return false

func on_incoming_attack(_attacker: CharacterBody2D, _hitbox: Hitbox):
	var roll: float = _rng.randf()
	var do_parry: bool = roll < parry_chance

	if do_parry and _state_machine != null:
		var profile = _owner_actor.get_parry_profile()
		if profile:
			_state_machine.on_parry_pressed(profile)

func _on_phase_changed(phase_data: Dictionary):
	if phase_data.get("state_name") == "ParryState" and phase_data.get("phase_name") == "SUCCESS":
		await get_tree().process_frame
		_decide_and_execute_action()

func _decide_and_execute_action():
	var possible_actions: Array[String] = ["normal_attack"]
	
	if _owner_actor.has_method("get_skill"):
		for skill_action in ["skill_x", "skill_y", "skill_a", "skill_b"]:
			if _owner_actor.get_skill(skill_action) != null:
				possible_actions.append(skill_action)
	
	if possible_actions.is_empty():
		return

	var chosen_action = possible_actions.pick_random()

	match chosen_action:
		"normal_attack":
			_execute_normal_attack()
		"skill_x", "skill_y", "skill_a", "skill_b":
			_execute_skill(chosen_action)
		_:
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
