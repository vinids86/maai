class_name PhysicsComponent
extends Node

var owner_node: CharacterBody2D

func _ready():
	owner_node = get_parent() as CharacterBody2D
	assert(owner_node != null, "PhysicsComponent deve ser filho de um CharacterBody2D.")

func apply_gravity(current_velocity: Vector2, delta: float) -> Vector2:
	if owner_node.is_on_floor():
		return current_velocity

	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	var new_velocity = current_velocity
	new_velocity.y += gravity * delta
	return new_velocity
