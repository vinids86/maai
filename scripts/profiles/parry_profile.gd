class_name ParryProfile
extends Resource

@export_group("Phases")
@export var active_duration: float = 0.15
@export var recovery_duration: float = 0.3

@export_group("Mechanics")
@export var stamina_cost: float = 5.0
@export var poise_bonus_on_success: float = 50.0
@export var poise_bonus_duration: float = 2.0

@export_group("Presentation")
@export var animation_name: StringName
@export var active_sfx: AudioStream
@export var success_sfx: AudioStream
@export var recovery_sfx: AudioStream
