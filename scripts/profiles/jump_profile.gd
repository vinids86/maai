class_name JumpProfile
extends Resource

@export_group("Animations")
@export var rising_animation: StringName
@export var falling_animation: StringName
@export var air_rising_animation: StringName

@export_group("Audio")
@export var jump_sfx: AudioStream
@export var landing_sfx: AudioStream
@export var air_jump_sfx: AudioStream

@export_group("Rules")
@export var coyote_time: float = 0.12
@export var max_air_jumps: int = 1

@export_group("Physics")
@export var air_control_speed: float = 300.0
@export var wall_jump_impulse: Vector2 = Vector2(400, -580)

@export_group("Variable Jump")
@export var min_jump_velocity: float = 260.0
@export var max_jump_velocity: float = 580.0
@export var max_hold_time: float = 0.08
@export var hold_accel: float = 4000.0
@export var release_cut_multiplier: float = 0.5
