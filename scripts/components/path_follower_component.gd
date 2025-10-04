class_name PathFollowerComponent
extends Node

var owner_node: CharacterBody2D
var _target: Node2D
var _last_target_local_position: Vector2
var _is_active: bool = false

func _ready():
	owner_node = get_parent() as CharacterBody2D
	assert(owner_node != null, "PathFollowerComponent must be a child of a CharacterBody2D.")

func start_following(target: Node2D):
	if not is_instance_valid(target):
		push_warning("PathFollowerComponent: Invalid target node provided.")
		_is_active = false
		return
	
	_target = target
	_last_target_local_position = target.position
	_is_active = true

func stop_following():
	_is_active = false
	_target = null
	_last_target_local_position = Vector2.ZERO

func calculate_target_velocity(delta: float) -> Vector2:
	if not _is_active or not is_instance_valid(_target):
		return Vector2.ZERO

	if delta == 0:
		return Vector2.ZERO

	var current_target_local_position = _target.position
	
	var local_displacement = current_target_local_position - _last_target_local_position
	
	var world_displacement = Vector2(local_displacement.x * owner_node.facing_sign, local_displacement.y)

	var calculated_velocity = world_displacement / delta
	
	_last_target_local_position = current_target_local_position
	
	return calculated_velocity
