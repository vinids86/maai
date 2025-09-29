# FacingComponent.gd
class_name FacingComponent
extends Node

## Referência para o nó dono (o Inimigo).
var _owner: CharacterBody2D

## O alvo que este componente deve seguir (o Player).
var _target_node: Node2D

## O interruptor binário. Se 'true', o componente tentará virar na direção do alvo.
var _is_active: bool = false

func _ready():
	_owner = get_parent()
	# Desativa o processamento por padrão para economizar recursos.
	set_process(false)

func _process(_delta):
	# Só executa se estiver ativo e se o dono e o alvo forem válidos.
	if _is_active and is_instance_valid(_owner) and is_instance_valid(_target_node):
		_update_facing_from_target()

## Liga o componente.
func enable(target: Node2D):
	if not is_instance_valid(target):
		push_warning("FacingComponent: Tentativa de ativar com um alvo inválido.")
		return
	
	_target_node = target
	_is_active = true
	# Ativa a função _process() para começar a seguir o alvo.
	set_process(true)

## Desliga o componente.
func disable():
	_is_active = false
	_target_node = null
	# Desativa a função _process() para parar de consumir recursos.
	set_process(false)

## Lógica principal: calcula a direção do alvo e atualiza a variável
## 'facing_sign' no script do dono (enemy.gd).
func _update_facing_from_target():
	var direction_to_target = _owner.global_position.direction_to(_target_node.global_position)
	
	if direction_to_target.x > 0.01:
		_owner.facing_sign = 1
	elif direction_to_target.x < -0.01:
		_owner.facing_sign = -1
