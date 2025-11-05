class_name CounterExecutionProfile
extends Resource

@export_group("Durations")
@export var ready_duration: float = 0.5
@export var vulnerable_duration: float = 0.8

@export_group("Presentation (Ready)")
@export var counter_ready_animation: StringName

@export_group("Presentation (Vulnerable)")
@export var victim_vulnerable_animation: StringName
