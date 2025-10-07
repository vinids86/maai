class_name DodgeProfile
extends Resource

@export_group("Phases")
@export var active_duration: float = 0.2
@export var recovery_duration: float = 0.1

@export_group("Movement")
@export var active_movement_velocity: Vector2 = Vector2.ZERO
@export var recovery_movement_velocity: Vector2 = Vector2.ZERO

@export_group("Mechanics")
@export var stamina_cost: float = 15.0
@export var poise_shield_contribution: float = 50.0

@export_group("Presentation")
@export var animation_name: StringName
@export var active_sfx: AudioStream
@export var recovery_sfx: AudioStream
