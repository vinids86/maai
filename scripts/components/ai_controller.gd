class_name AIController
extends Node

@onready var _state_machine: StateMachine = get_parent().find_child("StateMachine") as StateMachine

func get_walk_direction() -> float:
	# Por agora, o nosso "saco de pancada" não tem intenção de se mover.
	# No futuro, a lógica de perseguição, patrulha, etc., viverá aqui.
	return 0.0

func is_running() -> bool:
	# O inimigo não corre por agora.
	return false

# Chamada SINCRÔNICA feita pelo ImpactResolver antes de resolver o acerto.
# Mantém tudo mínimo: apenas delega ao StateMachine a lógica de parry.
func on_incoming_attack(attacker: CharacterBody2D, hitbox: Hitbox) -> void:
	if _state_machine != null:
		_state_machine.on_parry_pressed()
