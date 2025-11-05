extends CounterExecutionProfile
class_name PushCounterProfile

@export_group("Push Execution")
@export var executor_animation_name: StringName
@export var execution_duration: float = 0.5
@export var executor_attack_profile: AttackProfile

@export_group("Push Logic")
@export var switch_sides: bool = true

@export_group("SFX")
@export var sfx_ready: AudioStream
@export var sfx_executing: AudioStream
