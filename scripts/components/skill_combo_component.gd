# SkillComboComponent.gd (Corrigido)
class_name SkillComboComponent
extends Node

var _owner_actor: Node
var _state_machine: StateMachine
var _sequence_state: State

# Agora, guardamos o índice de combo para cada skill separadamente.
# A chave será o Resource da skill, e o valor será o índice do combo.
var _combo_indices: Dictionary = {}


func _ready():
	_owner_actor = get_parent()
	assert(_owner_actor != null, "SkillComboComponent deve ser filho de um nó de ator.")

	_state_machine = _owner_actor.find_child("StateMachine") as StateMachine
	assert(_state_machine != null, "SkillComboComponent: StateMachine não encontrada como irmã.")

	_sequence_state = _state_machine.find_child("SequenceState")
	assert(_sequence_state != null, "SkillComboComponent: Nó 'SequenceState' não encontrado na StateMachine.")

	_state_machine.transitioned.connect(_on_state_transitioned)

# A função agora recebe a skill que deve ser processada.
func get_next_skill_phase(skill: SequenceSkill) -> AttackSet:
	if not skill or skill.skill_phases.is_empty():
		return null
	
	# Pega o índice atual para esta skill, ou 0 se não existir.
	var current_index = _combo_indices.get(skill, 0)

	var next_index: int
	# A lógica de qual fase pegar permanece similar.
	if not _is_in_combo_state():
		next_index = 0
	elif current_index + 1 < skill.skill_phases.size():
		next_index = current_index + 1
	else:
		next_index = 0
	
	# Atualizamos o índice para esta skill.
	_combo_indices[skill] = next_index
	
	return skill.skill_phases[next_index]


func _on_state_transitioned(from_state: State, to_state: State):
	# Quando saímos do estado de sequência, é mais seguro
	# resetar todos os combos para o início.
	if from_state == _sequence_state and to_state != _sequence_state:
		_combo_indices.clear()

# --- FUNÇÃO ADICIONADA ---
# Esta função verifica se o personagem já está no meio de um combo de skill.
func _is_in_combo_state() -> bool:
	return _state_machine.get_current_state() == _sequence_state
