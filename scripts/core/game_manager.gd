extends Node

# Referência global ao Player
var player_node: Player = null:
	set(new_player_node):
		if is_instance_valid(new_player_node):
			player_node = new_player_node
		else:
			player_node = null

# Sinais Globais de Combate
signal combat_state_changed(is_in_combat: bool)

# Gerenciamento de Aggro
var _aggro_list: Array[Node] = []
var _is_in_combat: bool = false

func register_player(player: Player) -> void:
	player_node = player

func unregister_player() -> void:
	player_node = null

# --- SISTEMA DE TENSÃO DE COMBATE ---

func register_aggro(enemy: Node) -> void:
	if not _aggro_list.has(enemy):
		_aggro_list.append(enemy)
		_check_combat_state()

func unregister_aggro(enemy: Node) -> void:
	if _aggro_list.has(enemy):
		_aggro_list.erase(enemy)
		_check_combat_state()

func _check_combat_state() -> void:
	# Limpeza de nós inválidos (caso algum inimigo tenha sido liberado sem avisar)
	for i in range(_aggro_list.size() - 1, -1, -1):
		if not is_instance_valid(_aggro_list[i]):
			_aggro_list.remove_at(i)
	
	var should_be_in_combat = _aggro_list.size() > 0
	
	if _is_in_combat != should_be_in_combat:
		_is_in_combat = should_be_in_combat
		combat_state_changed.emit(_is_in_combat)

# Helper para forçar estado (útil para cutscenes ou eventos scriptados)
func force_combat_state(active: bool) -> void:
	if active:
		# Adiciona um nó dummy ou marcador se necessário, ou apenas força o flag
		# Por enquanto, vamos manter simples e confiar na lista
		pass 
	else:
		_aggro_list.clear()
		_check_combat_state()
