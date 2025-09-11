class_name LocomotionState
extends State

@export var locomotion_profile: LocomotionProfile

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func process_physics(delta: float, is_running: bool = false):
	if not owner_node.is_on_floor():
		owner_node.velocity.y += gravity * delta

	if not locomotion_profile:
		push_warning("LocomotionState não tem um LocomotionProfile atribuído no Inspetor.")
		return

	var walk_direction = Input.get_axis("move_left", "move_right")
	
	_update_facing_sign(walk_direction)
	
	movement_component.calculate_walk_velocity(walk_direction, is_running, locomotion_profile)

func process_input(event: InputEvent):
	pass

func allow_dodge() -> bool:
	return owner_node.is_on_floor()

func _update_facing_sign(direction: float):
	if owner_node.facing_locked:
		return
		
	if direction > 0:
		owner_node.facing_sign = 1
	elif direction < 0:
		owner_node.facing_sign = -1
