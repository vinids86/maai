class_name PathFollowerComponent
extends Node

var owner_node: CharacterBody2D
var _target_node: Node2D
var _last_target_position: Vector2
var _is_following: bool = false

func _ready():
	owner_node = get_parent() as CharacterBody2D
	assert(owner_node != null, "PathFollowerComponent deve ser filho de um CharacterBody2D.")

func start_following(target: Node2D):
	if not is_instance_valid(target):
		return
	
	_target_node = target
	_last_target_position = _target_node.global_position
	_is_following = true

func stop_following():
	_is_following = false
	_target_node = null

func calculate_target_velocity(delta: float) -> Vector2:
	if not _is_following or not is_instance_valid(_target_node):
		return Vector2.ZERO

	var current_target_position = _target_node.global_position
	var displacement = current_target_position - _last_target_position
	
	_last_target_position = current_target_position
	
	if delta > 0:
		return displacement / delta
	
	return Vector2.ZERO
