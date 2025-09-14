class_name LocomotionProfile
extends Resource

@export_group("Physics")
@export var speed: float = 300.0
@export var run_speed: float = 500.0

@export_group("Mechanics")
@export var base_poise: float = 5.0

@export_group("Presentation")
@export var idle_animation: StringName
@export var walk_animation: StringName
@export var run_animation: StringName
