class_name AIController
extends Node

@export var parry_chance: float = 0.30

var _rng: RandomNumberGenerator
var _owner_actor: Node
@onready var _state_machine: StateMachine = get_parent().find_child("StateMachine") as StateMachine

func _ready():
	_owner_actor = get_parent()
	assert(_owner_actor != null, "AIController deve ser filho de um nó de ator.")

	parry_chance = clampf(parry_chance, 0.0, 1.0)

	_rng = RandomNumberGenerator.new()
	_rng.randomize()

	ImpactResolver.impact_resolved.connect(_on_impact_resolved)

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

func _on_impact_resolved(result: ImpactResolver.ContactResult):
	if result == null or _owner_actor == null:
		return

	if result.defender_node == _owner_actor:
		if result.defender_outcome == ImpactResolver.ContactResult.DefenderOutcome.PARRY_SUCCESS:
			if _state_machine != null:
				await get_tree().process_frame
				var profile = _owner_actor.get_next_attack_in_combo()
				if profile:
					_state_machine.on_attack_pressed(profile)
