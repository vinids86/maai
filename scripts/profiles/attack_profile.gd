class_name AttackProfile
extends Resource

enum ParryInteractionType {
	STANDARD,
	UNPARRYABLE
}

enum UnparryableType {
	NONE,
	THRUST,
	SWEEP
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
@export var impact_sfx: AudioStream

@export_group("Hitbox")
@export var hitbox_size: Vector2 = Vector2(90, 64)
@export var hitbox_position: Vector2 = Vector2(90, -64)

@export_group("Mechanics")
@export var damage: float = 1.0
@export var stamina_cost: float = 0.0
@export var stamina_damage: float = 10.0
@export var poise_impact_contribution: float = 10.0
@export var poise_momentum_gain: float = 0.0
@export var poise_momentum_duration: float = 1.5
@export var knockback_vector: Vector2 = Vector2(150, -100)
@export var parry_interaction: ParryInteractionType = ParryInteractionType.STANDARD
@export var unparryable_type: UnparryableType = UnparryableType.NONE

@export_group("Movement")
@export var startup_movement_velocity: Vector2 = Vector2.ZERO
@export var active_movement_velocity: Vector2 = Vector2.ZERO
@export var recovery_movement_velocity: Vector2 = Vector2.ZERO
@export var link_movement_velocity: Vector2 = Vector2.ZERO

@export_group("Poise Contributions per Phase (Defensivo)")
@export var startup_poise_shield: float = 10.0
@export var active_poise_shield: float = 10.0
@export var recovery_poise_shield: float = 300.0
