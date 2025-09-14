class_name PoiseComponent
extends Node

@onready var state_machine: StateMachine = get_parent().find_child("StateMachine")

var poise_momentum: float = 0.0
var _active_bonuses: Array[Dictionary] = []

func _ready():
	assert(state_machine != null, "PoiseComponent: StateMachine não encontrada como irmã.")

func _physics_process(delta: float):
	for i in range(_active_bonuses.size() - 1, -1, -1):
		var bonus = _active_bonuses[i]
		bonus.time_left -= delta
		if bonus.time_left <= 0:
			_active_bonuses.remove_at(i)

func get_effective_poise() -> float:
	var current_state = state_machine.get_current_state()
	var state_poise: float = 0.0
	
	if current_state and current_state.has_method("get_current_poise"):
		state_poise = current_state.get_current_poise()
	
	var total_bonus_value: float = 0.0
	for bonus in _active_bonuses:
		total_bonus_value += bonus.value
		
	return state_poise + poise_momentum + total_bonus_value

func apply_poise_bonus(value: float, duration: float):
	_active_bonuses.append({
		"value": value,
		"time_left": duration
	})

func add_momentum(amount: float):
	poise_momentum += amount

func reset_momentum():
	poise_momentum = 0.0
