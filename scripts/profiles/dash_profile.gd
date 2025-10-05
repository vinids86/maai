class_name DashProfile
extends Resource

@export_group("Phases")
@export var active_duration: float = 0.12
@export var recovery_duration: float = 0.10

@export_group("Presentation")
@export var animation_name: StringName

@export_group("Audio")
@export var active_sfx: AudioStream
@export var recovery_sfx: AudioStream

@export_group("Mechanics")
@export var stamina_cost: float = 10.0
