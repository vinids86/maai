class_name WallDetectorComponent
extends Node2D

@onready var raycast: RayCast2D = $RayCast2D

func is_colliding(facing_direction: int) -> bool:
	if not is_instance_valid(raycast):
		return false
	
	raycast.target_position.x = abs(raycast.target_position.x) * facing_direction
	raycast.force_raycast_update()
	
	return raycast.is_colliding()
