extends Node

var player_node: Node:
	set(new_player_node):
		if is_instance_valid(new_player_node):
			player_node = new_player_node
		else:
			player_node = null

func unregister_player() -> void:
	player_node = null
