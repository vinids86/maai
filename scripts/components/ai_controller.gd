class_name AIController
extends Node

@export var parry_chance: float = 0.30  # 0.0 a 1.0

var _rng: RandomNumberGenerator
@onready var _state_machine: StateMachine = get_parent().find_child("StateMachine") as StateMachine
@onready var _impact_resolver: ImpactResolver = ImpactResolver

func _ready() -> void:
	# Sanitiza chance e prepara RNG
	parry_chance = clampf(parry_chance, 0.0, 1.0)

	_rng = RandomNumberGenerator.new()
	_rng.randomize()

	if _impact_resolver != null:
		_impact_resolver.connect("impact_resolved", Callable(self, "_on_impact_resolved"))

func get_walk_direction() -> float:
	return 0.0

func is_running() -> bool:
	return false

# Aviso SINCRÔNICO do ImpactResolver antes de resolver o contato.
# Decisão: rolagem aleatória simples por impacto.
func on_incoming_attack(attacker: CharacterBody2D, hitbox: Hitbox) -> void:
	var roll: float = _rng.randf()
	var do_parry: bool = roll < parry_chance

	if do_parry and _state_machine != null:
		_state_machine.on_parry_pressed()

# Pós-parry bem-sucedido: pede ataque (mantém seu comportamento atual).
func _on_impact_resolved(result: ImpactResolver.ContactResult) -> void:
	var owner_actor: CharacterBody2D = get_parent() as CharacterBody2D
	if result == null or owner_actor == null:
		return

	if result.defender_node == owner_actor:
		if result.defender_outcome == ImpactResolver.ContactResult.DefenderOutcome.PARRY_SUCCESS:
			if _state_machine != null:
				await get_tree().process_frame
				_state_machine.on_attack_pressed()
