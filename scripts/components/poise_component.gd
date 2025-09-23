class_name PoiseComponent
extends Node

@onready var state_machine: StateMachine = get_parent().find_child("StateMachine")

var _shield_bonuses: Array[Dictionary] = []
var _sword_bonuses: Array[Dictionary] = []

func _ready():
	assert(state_machine != null, "PoiseComponent: StateMachine não encontrada como irmã.")
	ImpactResolver.impact_resolved.connect(_on_impact_resolved)

func _physics_process(delta: float):
	for i in range(_shield_bonuses.size() - 1, -1, -1):
		var bonus = _shield_bonuses[i]
		bonus.time_left -= delta
		if bonus.time_left <= 0:
			_shield_bonuses.remove_at(i)
			
	for i in range(_sword_bonuses.size() - 1, -1, -1):
		var bonus = _sword_bonuses[i]
		bonus.time_left -= delta
		if bonus.time_left <= 0:
			_sword_bonuses.remove_at(i)

func get_effective_shield_poise() -> float:
	var owner_node = get_parent()
	var base_poise = owner_node.get("base_poise")
	
	var action_shield_contribution: float = 0.0
	var current_state = state_machine.get_current_state()
	if current_state and current_state.has_method("get_poise_shield_contribution"):
		action_shield_contribution = current_state.get_poise_shield_contribution()

	var total_bonus_value: float = 0.0
	for bonus in _shield_bonuses:
		total_bonus_value += bonus.value
		
	return base_poise + action_shield_contribution + total_bonus_value

func get_effective_offensive_poise() -> float:
	var owner_node = get_parent()
	var base_poise = owner_node.get("base_poise")
	
	var action_impact_contribution: float = 0.0
	var current_state = state_machine.get_current_state()
	if current_state and current_state.has_method("get_poise_impact_contribution"):
		action_impact_contribution = current_state.get_poise_impact_contribution()

	var total_bonus_value: float = 0.0
	for bonus in _sword_bonuses:
		total_bonus_value += bonus.value
		
	return base_poise + action_impact_contribution + total_bonus_value

func apply_shield_bonus(value: float, duration: float):
	_shield_bonuses.append({
		"value": value,
		"time_left": duration
	})

func apply_sword_bonus(value: float, duration: float):
	_sword_bonuses.append({
		"value": value,
		"time_left": duration
	})

func _on_impact_resolved(result: ContactResult):
	var owner_node = get_parent()
	
	if result.attacker_node == owner_node:
		if result.defender_outcome == ContactResult.DefenderOutcome.HIT or \
		   result.defender_outcome == ContactResult.DefenderOutcome.BLOCKED:
			
			if result.attack_profile:
				apply_sword_bonus(
					result.attack_profile.poise_momentum_gain,
					result.attack_profile.poise_momentum_duration
				)
