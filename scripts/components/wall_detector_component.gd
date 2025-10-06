class_name WallDetectorComponent
extends Node2D

@onready var raycast: RayCast2D = $RayCast2D

func is_on_wall(facing_direction: int, walk_direction: float) -> bool:
	if not is_instance_valid(raycast):
		return false

	raycast.target_position.x = abs(raycast.target_position.x) * facing_direction
	raycast.force_raycast_update()
	
	var is_colliding = raycast.is_colliding()
	var is_pressing_against_wall = (walk_direction * facing_direction) > 0

	return is_colliding and is_pressing_against_wall
