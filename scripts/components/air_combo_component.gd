class_name AirComboComponent
extends Node

@export var attack_set: AttackSet

var _owner_actor: Node
var _state_machine: StateMachine
var _airborne_state: State
var _air_attack_state: State

var _combo_index: int = 0

func _ready():
	_owner_actor = get_parent()
	_state_machine = _owner_actor.find_child("StateMachine") as StateMachine
	_airborne_state = _state_machine.find_child("AirborneState")
	_air_attack_state = _state_machine.find_child("AirAttackState")
	
	assert(_owner_actor != null, "AirComboComponent deve ser filho de um nó de ator.")
	assert(_state_machine != null, "AirComboComponent: StateMachine não encontrada como irmã.")
	assert(_airborne_state != null, "AirComboComponent: Nó 'AirborneState' não encontrado na StateMachine.")
	assert(_air_attack_state != null, "AirComboComponent: Nó 'AirAttackState' não encontrado na StateMachine.")
	
	_state_machine.transitioned.connect(_on_state_transitioned)

func get_next_attack_profile() -> AttackProfile:
	if not attack_set or not "attacks" in attack_set or attack_set.attacks.is_empty():
		return null

	var next_index: int
	if not _is_in_air_state():
		next_index = 0
	elif _combo_index < attack_set.attacks.size(): 
		next_index = _combo_index
	else:
		next_index = 0

	return attack_set.attacks[next_index]

func advance_combo():
	if _combo_index + 1 < attack_set.attacks.size():
		_combo_index += 1
	else:
		_combo_index = 0

func reset_combo():
	_combo_index = 0

func _on_state_transitioned(_from_state: State, to_state: State):
	if to_state != _airborne_state and to_state != _air_attack_state:
		reset_combo()

func _is_in_air_state() -> bool:
	if not is_instance_valid(_state_machine): return false
	var current = _state_machine.get_current_state()
	return current == _airborne_state or current == _air_attack_state
