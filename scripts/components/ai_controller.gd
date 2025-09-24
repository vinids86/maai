class_name AIController
extends Node

@export var parry_chance: float = 0.30

var _rng: RandomNumberGenerator
var _owner_actor: Node
@onready var _state_machine: StateMachine = get_parent().find_child("StateMachine")

func _ready():
	_owner_actor = get_parent()
	assert(_owner_actor != null, "AIController deve ser filho de um nó de ator.")

	parry_chance = clampf(parry_chance, 0.0, 1.0)

	_rng = RandomNumberGenerator.new()
	_rng.randomize()

	if _state_machine:
		_state_machine.phase_changed.connect(_on_phase_changed)

func get_walk_direction() -> float:
	return 0.0

func is_running() -> bool:
	return false

func on_incoming_attack(attacker: CharacterBody2D, hitbox: Hitbox):
	var roll: float = _rng.randf()
	var do_parry: bool = roll < parry_chance

	if do_parry and _state_machine != null:
		var profile = _owner_actor.get_parry_profile()
		if profile:
			_state_machine.on_parry_pressed(profile)

func _on_phase_changed(phase_data: Dictionary):
	if phase_data.get("state_name") == "ParryState" and phase_data.get("phase_name") == "SUCCESS":
		await get_tree().process_frame
		
		# Gera um número aleatório entre 0.0 e 1.0
		# Se for menor que 0.3, temos uma chance de 30%
		if randf() < 1.0:
			# 30% de chance: executa a skill de sequência
			_state_machine.on_sequence_skill_pressed(_owner_actor.skill_combo_component.get_next_skill_phase())
		else:
			# 70% de chance: executa o ataque normal do combo
			var combo_component = _owner_actor.find_child("ComboComponent")
			if combo_component:
				var profile = combo_component.get_next_attack_profile()
				if profile:
					_state_machine.on_attack_pressed(profile)
