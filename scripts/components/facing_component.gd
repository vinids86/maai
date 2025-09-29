class_name FacingComponent
extends Node

var _owner: CharacterBody2D

var _target_node: Node2D

var _is_active: bool = false

func _ready():
	_owner = get_parent()
	set_process(false)

func _process(_delta):
	if _is_active and is_instance_valid(_owner) and is_instance_valid(_target_node):
		_update_facing_from_target()

func enable(target: Node2D):
	if not is_instance_valid(target):
		push_warning("FacingComponent: Tentativa de ativar com um alvo inválido.")
		return
	
	_target_node = target
	_is_active = true
	set_process(true)

func disable():
	_is_active = false
	_target_node = null
	set_process(false)

func _update_facing_from_target():
	var direction_to_target = _owner.global_position.direction_to(_target_node.global_position)
	
	if direction_to_target.x > 0.01:
		_owner.facing_sign = 1
	elif direction_to_target.x < -0.01:
		_owner.facing_sign = -1
