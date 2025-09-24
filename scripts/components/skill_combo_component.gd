class_name SkillComboComponent
extends Node

var _owner_actor: Node
var _state_machine: StateMachine
var _sequence_state: State

var _combo_index: int = 0

func _ready():
	_owner_actor = get_parent()
	assert(_owner_actor != null, "SkillComboComponent deve ser filho de um nó de ator.")

	_state_machine = _owner_actor.find_child("StateMachine") as StateMachine
	assert(_state_machine != null, "SkillComboComponent: StateMachine não encontrada como irmã.")

	_sequence_state = _state_machine.find_child("SequenceState")
	assert(_sequence_state != null, "SkillComboComponent: Nó 'SequenceState' não encontrado na StateMachine.")

	_state_machine.transitioned.connect(_on_state_transitioned)

func get_next_skill_phase() -> AttackSet:
	var skill_set = _owner_actor.skill_set
	if not skill_set or skill_set.skill_phases.is_empty():
		return null

	var next_index: int
	if not _is_in_combo_state():
		next_index = 0
	elif _has_next_phase(skill_set):
		next_index = _combo_index + 1
	else:
		next_index = 0

	return skill_set.skill_phases[next_index]

func _on_state_transitioned(from_state: State, to_state: State):
	if from_state == _sequence_state and to_state == _sequence_state:
		if _has_next_phase(_owner_actor.skill_set):
			_advance_combo()
		else:
			_combo_index = 0
		return

	if from_state == _sequence_state and to_state != _sequence_state:
		_combo_index = 0

func _is_in_combo_state() -> bool:
	return _state_machine.get_current_state() == _sequence_state

func _has_next_phase(set: SkillSet) -> bool:
	return _combo_index + 1 < set.skill_phases.size()

func _advance_combo():
	_combo_index += 1
