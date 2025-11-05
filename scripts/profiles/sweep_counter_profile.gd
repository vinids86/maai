extends CounterExecutionProfile
class_name SweepCounterProfile

@export_group("Execution")
@export var executor_animation_name: StringName
@export var execution_duration: float
@export var executor_attack_profile: AttackProfile

@export_group("Presentation")
@export var sfx_ready: AudioStream
@export var sfx_executing: AudioStream
