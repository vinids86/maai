class_name AttackProfile
extends Resource

@export_group("Phases")
@export var startup_duration: float = 0.2
@export var active_duration: float = 0.15
@export var recovery_duration: float = 0.25

@export_group("Presentation")
@export var animation_name: StringName
@export var startup_sfx: AudioStream
@export var active_sfx: AudioStream
@export var recovery_sfx: AudioStream

@export_group("Hitbox")
@export var hitbox_size: Vector2 = Vector2(32, 32)
@export var hitbox_position: Vector2 = Vector2(40, 0)

@export_group("Movement")
@export var movement_velocity: Vector2 = Vector2.ZERO

@export_group("Mechanics")
@export var damage: float = 10.0
