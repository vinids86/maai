class_name ComboComponent
extends Node

var _owner_actor: Node
var _state_machine: StateMachine
var _attack_state: State

var _combo_index: int = 0

func _ready():
	_owner_actor = get_parent()
	assert(_owner_actor != null, "ComboComponent deve ser filho de um nó de ator.")

	_state_machine = _owner_actor.find_child("StateMachine") as StateMachine
	assert(_state_machine != null, "ComboComponent: StateMachine não encontrada como irmã.")

	_attack_state = _state_machine.find_child("AttackState")
	assert(_attack_state != null, "ComboComponent: Nó 'AttackState' não encontrado na StateMachine.")

	_state_machine.transitioned.connect(_on_state_transitioned)

func get_next_attack_profile() -> AttackProfile:
	var attack_set = _owner_actor.attack_set
	if not attack_set or attack_set.attacks.is_empty():
		return null

	var next_index: int
	if not _is_in_combo_state():
		next_index = 0
	elif _has_next_attack(attack_set):
		next_index = _combo_index + 1
	else:
		next_index = 0

	return attack_set.attacks[next_index]

func _on_state_transitioned(from_state: State, to_state: State):
	if from_state == _attack_state and to_state == _attack_state:
		if _has_next_attack(_owner_actor.attack_set):
			_advance_combo()
		else:
			_combo_index = 0
		return

	if from_state == _attack_state and to_state != _attack_state:
		_combo_index = 0

func _is_in_combo_state() -> bool:
	return _state_machine.get_current_state() == _attack_state

func _has_next_attack(set: AttackSet) -> bool:
	return _combo_index + 1 < set.attacks.size()

func _advance_combo():
	_combo_index += 1
