class_name AIController
extends Node

@export var parry_every_n: int = 2
var _incoming_counter: int = 0

@onready var _state_machine: StateMachine = get_parent().find_child("StateMachine") as StateMachine
@onready var _impact_resolver: ImpactResolver = ImpactResolver

func _ready() -> void:
	if _impact_resolver != null:
		_impact_resolver.connect("impact_resolved", Callable(self, "_on_impact_resolved"))

func get_walk_direction() -> float:
	return 0.0

func is_running() -> bool:
	return false

# Aviso SINCRÔNICO do ImpactResolver antes de resolver o contato.
# Decisão: a cada N impactos, tenta parry; nos demais, deixa o autoblock acontecer.
func on_incoming_attack(attacker: CharacterBody2D, hitbox: Hitbox) -> void:
	_incoming_counter += 1
	if parry_every_n <= 0:
		parry_every_n = 3

	var do_parry: bool = false
	if (_incoming_counter % parry_every_n) == 0:
		do_parry = true

	if do_parry and _state_machine != null:
		_state_machine.on_parry_pressed()

# Pós-parry bem-sucedido: reseta o ciclo e pede ataque (mesma regra já usada).
func _on_impact_resolved(result: ImpactResolver.ContactResult) -> void:
	var owner_actor: CharacterBody2D = get_parent() as CharacterBody2D
	if result == null or owner_actor == null:
		return

	if result.defender_node == owner_actor:
		if result.defender_outcome == ImpactResolver.ContactResult.DefenderOutcome.PARRY_SUCCESS:
			_incoming_counter = 0
			if _state_machine != null:
				await get_tree().process_frame
				_state_machine.on_attack_pressed()
