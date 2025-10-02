class_name ParriedProfile
extends Resource

@export_group("Presentation")
@export var animation_name: StringName
@export var sfx: AudioStream

@export_group("Phases")
@export var recoil_duration: float = 0.15
@export var reactive_duration: float = 0.25

@export_group("Mechanics")
@export var poise_shield_contribution: float = 500.0
