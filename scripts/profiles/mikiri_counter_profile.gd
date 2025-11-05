class_name MikiriCounterProfile
extends CounterExecutionProfile

@export_group("Execution")
@export var executor_animation: StringName
@export var execution_duration: float = 0.6
@export var executor_attack_profile: AttackProfile

@export_group("Presentation (Execution)")
@export var mikiri_sfx: AudioStream
