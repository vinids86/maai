class_name AirMobilityComponent
extends Node

## Componente responsável por gerenciar recursos de movimento aéreo.
## Funciona como a "autoridade" de quantos pulos e dashes restam.

var _player: Node
var _surface_contact_component: Node

# Estado atual
var air_jumps_left: int = 0
var air_dash_available: bool = true

## Configura as dependências do componente. Deve ser chamado no _ready do Player.
func setup(player: Node, surface_contact: Node) -> void:
	_player = player
	_surface_contact_component = surface_contact
	
	if _surface_contact_component:
		if not _surface_contact_component.is_connected("landed", _on_landed):
			_surface_contact_component.connect("landed", _on_landed)
	
	# Garante que começamos com os recursos cheios
	reset_resources()

## Chamado automaticamente pelo sinal landed
func _on_landed() -> void:
	reset_resources()

func reset_resources() -> void:
	# Reseta o Dash
	air_dash_available = true
	
	# Reseta os Pulos lendo do perfil atual do player
	if _player and _player.has_method("get_jump_profile"):
		var profile = _player.get_jump_profile()
		if profile:
			air_jumps_left = profile.max_air_jumps
		else:
			air_jumps_left = 0 # Fallback seguro

# --- Lógica de Pulos ---

## Verifica se é possível pular (apenas leitura)
func can_air_jump() -> bool:
	return air_jumps_left > 0

## Tenta consumir um pulo aéreo. Retorna true se conseguiu gastar.
func try_consume_air_jump() -> bool:
	if air_jumps_left > 0:
		air_jumps_left -= 1
		return true
	return false

# --- Lógica de Dash ---

## Tenta consumir o dash aéreo. Retorna true se conseguiu gastar.
func try_consume_air_dash() -> bool:
	if air_dash_available:
		air_dash_available = false
		return true
	return false
