# This is a data container for movement-related variables.
# By making it a Resource, we can create and edit different movement profiles
# directly in the Godot Inspector and save them as .tres files.
class_name LocomotionProfile
extends Resource

@export var speed: float = 300.0
@export var run_speed: float = 500.0
