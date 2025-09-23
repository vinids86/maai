class_name FinisherProfile
extends Resource

@export_group("Presentation")
@export var ready_duration: float = 2.0
@export var animation_name: StringName
@export var sfx: AudioStream

@export_group("Mechanics")
@export var poise_shield_contribution: float = 100.0
@export var attack_profile: AttackProfile
