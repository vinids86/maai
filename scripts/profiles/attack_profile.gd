class_name AttackProfile
extends Resource

enum ParryInteractionType {
	STANDARD,
	UNPARRYABLE
}

@export_group("Phases")
@export var startup_duration: float = 0.3
@export var active_duration: float = 0.1
@export var recovery_duration: float = 0.2
@export var link_duration: float = 0.6

@export_group("Presentation")
@export var animation_name: StringName
@export var startup_sfx: AudioStream
@export var active_sfx: AudioStream
@export var recovery_sfx: AudioStream

@export_group("Hitbox")
@export var hitbox_size: Vector2 = Vector2(32, 32)
@export var hitbox_position: Vector2 = Vector2(40, 0)

@export_group("Mechanics")
@export var damage: float = 10.0
@export var stamina_cost: float = 0.0
@export var stamina_damage: float = 10.0
@export var poise_damage: float = 10.0
@export var poise_momentum_gain: float = 5.0
@export var action_poise: float = 10.0
@export var knockback_vector: Vector2 = Vector2(150, -100)
@export var parry_interaction: ParryInteractionType = ParryInteractionType.STANDARD

@export_group("Movement")
@export var startup_movement_velocity: Vector2 = Vector2.ZERO
@export var active_movement_velocity: Vector2 = Vector2.ZERO
@export var recovery_movement_velocity: Vector2 = Vector2.ZERO
@export var link_movement_velocity: Vector2 = Vector2.ZERO
