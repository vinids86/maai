class_name AIController
extends Node

func get_walk_direction() -> float:
	# Por agora, o nosso "saco de pancada" não tem intenção de se mover.
	# No futuro, a lógica de perseguição, patrulha, etc., viverá aqui.
	return 0.0

func is_running() -> bool:
	# O inimigo não corre por agora.
	return false
