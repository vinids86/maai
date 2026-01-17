# scripts/profiles/mikiri_counter_profile.gd
class_name MikiriCounterProfile
extends CounterExecutionProfile

@export_group("Execution")
@export var executor_animation: StringName
@export var execution_duration: float = 0.6
@export var executor_attack_profile: AttackProfile

@export_group("Victim Reaction")
@export var victim_animation_name: StringName = "thrust_countered" # Animação da espada baixando
@export var snap_bone_name: String = "mikiri_snap_point" # Nome do Point Attachment no Spine do Inimigo
@export var player_foot_offset: Vector2 = Vector2(0, 0) # Ajuste fino se necessário

@export_group("Presentation")
@export var mikiri_sfx: AudioStream
