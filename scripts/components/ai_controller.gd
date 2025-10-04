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

var _player_combo_hits_count: int = 0

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

func _on_player_exited_detection_area(body: Node2D):
	if body == GameManager.player_node:
		_facing_component.disable()

func get_walk_direction() -> float:
	return 0.0

func is_running() -> bool:
	return false

func on_incoming_attack(_attacker: CharacterBody2D, _hitbox: Hitbox):
	_player_combo_hits_count += 1
	
	var do_parry: bool = false
	
	match _player_combo_hits_count:
		1:
			do_parry = false
		2:
			do_parry = _rng.randf() < 0.60
		3:
			do_parry = true

	if do_parry and _state_machine != null:
		var profile = _owner_actor.get_parry_profile()
		if profile:
			_state_machine.on_parry_pressed(profile)
			_player_combo_hits_count = 0
	
	if _player_combo_hits_count >= 3:
		_player_combo_hits_count = 0

func _on_phase_changed(phase_data: Dictionary):
	if phase_data.get("state_name") == "ParryState" and phase_data.get("phase_name") == "SUCCESS":
		await get_tree().process_frame
		_decide_and_execute_action()

func _decide_and_execute_action():
	var roll: float = _rng.randf()

	if roll < 0.60:
		_execute_normal_attack()
	elif roll < 0.80:
		if _owner_actor.has_method("get_skill") and _owner_actor.get_skill("skill_x"):
			_execute_skill("skill_x")
		else:
			_execute_normal_attack()
	elif roll < 0.90:
		if _owner_actor.has_method("get_skill") and _owner_actor.get_skill("skill_y"):
			_execute_skill("skill_y")
		else:
			_execute_normal_attack()
	else: 
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
