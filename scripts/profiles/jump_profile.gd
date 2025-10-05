class_name JumpProfile
extends Resource

@export_group("Physics")
@export var jump_velocity: float = -400.0
@export var air_control_speed: float = 200.0

@export_group("Presentation")
@export var rising_animation: StringName
@export var falling_animation: StringName
@export var landing_animation: StringName
@export var jump_sfx: AudioStream
@export var landing_sfx: AudioStream
