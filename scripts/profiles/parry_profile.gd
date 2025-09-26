class_name ParryProfile
extends Resource

@export_group("Phases")
@export var active_duration: float = 0.15
@export var recovery_duration: float = 0.3
@export var success_duration: float = 0.2

@export_group("Mechanics")
@export var stamina_cost: float = 5.0
@export var poise_shield_contribution: float = 30.0
@export var shield_bonus_on_success: float = 50.0
@export var sword_bonus_on_success: float = 25.0
@export var bonus_duration: float = 0.5

@export_group("Presentation")
@export var animation_name: StringName
@export var active_sfx: AudioStream
@export var success_sfx: AudioStream
@export var recovery_sfx: AudioStream
