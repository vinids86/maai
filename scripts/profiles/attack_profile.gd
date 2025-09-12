class_name AttackProfile
extends Resource

@export_group("Phases")
@export var startup_duration: float = 0.2
@export var active_duration: float = 0.15
@export var recovery_duration: float = 0.25

@export_group("Presentation")
@export var animation_name: StringName
@export var startup_sfx: AudioStream
@export var active_sfx: AudioStream
@export var recovery_sfx: AudioStream

# No futuro, adicionaremos aqui propriedades como dano, dano de poise, etc.
