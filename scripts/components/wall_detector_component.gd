class_name WallDetectorComponent
extends Node2D

@onready var raycast: RayCast2D = $RayCast2D
@onready var floor_detector: RayCast2D = $FloorDetector

func is_colliding(facing_direction: int) -> bool:
	if not is_instance_valid(raycast):
		return false
	
	raycast.target_position.x = abs(raycast.target_position.x) * facing_direction
	raycast.force_raycast_update()
	
	return raycast.is_colliding()

func has_floor_ahead(facing_direction: int) -> bool:
	if not is_instance_valid(floor_detector):
		# Se não tiver detector de chão, assume que tem chão (seguro) para não travar
		return true 
	
	# Ajusta a posição X do alvo baseado na direção, similar ao wall detector
	floor_detector.target_position.x = abs(floor_detector.target_position.x) * facing_direction
	floor_detector.force_raycast_update()
	
	return floor_detector.is_colliding()
