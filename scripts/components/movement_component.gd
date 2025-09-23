class_name MovementComponent
extends Node

var owner_node: CharacterBody2D

func _ready():
	owner_node = get_parent() as CharacterBody2D
	assert(owner_node != null, "MovementComponent deve ser filho de um CharacterBody2D.")

func calculate_walk_velocity(walk_direction: float, is_running: bool, profile: LocomotionProfile):
	if not profile:
		return

	var target_speed = profile.speed
	if is_running:
		target_speed = profile.run_speed
		
	if walk_direction:
		owner_node.velocity.x = walk_direction * target_speed
	else:
		owner_node.velocity.x = move_toward(owner_node.velocity.x, 0, profile.speed)

func apply_dodge_velocity(direction: Vector2, profile: DodgeProfile):
	if not profile:
		return
	
	owner_node.velocity = Vector2.ZERO

	if direction == Vector2.ZERO:
		return

	var final_velocity: Vector2

	if direction.y != 0:
		final_velocity.x = direction.x * profile.speed
		final_velocity.y = direction.y * profile.speed
	else:
		final_velocity = direction.normalized() * profile.speed
	
	owner_node.velocity = final_velocity

func apply_gravity(delta: float):
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	if not owner_node.is_on_floor():
		owner_node.velocity.y += gravity * delta
