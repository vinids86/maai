class_name JumpProfile
extends Resource

@export_group("Animations")
@export var rising_animation: StringName
@export var falling_animation: StringName

@export_group("Audio")
@export var jump_sfx: AudioStream
@export var landing_sfx: AudioStream

@export_group("Physics")
@export var air_control_speed: float = 200.0
@export var jump_velocity: float = 320.0

@export_group("Variable Jump")
@export var min_jump_velocity: float = 260.0
@export var max_jump_velocity: float = 360.0
@export var max_hold_time: float = 0.12
@export var hold_accel: float = 2000.0
@export var release_cut_multiplier: float = 0.35
