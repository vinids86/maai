# This is a data container for dodge-related variables.
# Each type of dodge (neutral, forward, etc.) can have its own profile.
class_name DodgeProfile
extends Resource

@export_group("Durations")
@export var active_duration: float = 0.25 # The duration of the actual dash/i-frames
@export var recovery_duration: float = 0.15

@export_group("Physics")
@export var speed: float = 750.0
