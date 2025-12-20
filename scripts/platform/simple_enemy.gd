class_name SimpleEnemy
extends CharacterBody2D

@onready var state_machine = $SimpleStateMachine
@onready var spine_sprite: SpineSprite = $SpineSprite
@onready var animation_component: AnimationComponent = $AnimationComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var physics_component: PhysicsComponent = $PhysicsComponent
@onready var surface_contact_component: SurfaceContactComponent = $SurfaceContactComponent
@onready var wall_detector: WallDetectorComponent = $WallDetectorComponent
@onready var hitbox: Hitbox = $Hitbox

@export var attack_profile: AttackProfile
@export var locomotion_profile: LocomotionProfile
@export var death_profile: DeathProfile

@export_group("Visual Identity")
@export var enemy_tint_color: Color = Color.WHITE
@export_range(0.0, 1.0) var enemy_tint_intensity: float = 0.0

func _ready() -> void:
	animation_component.setup(null, spine_sprite, state_machine)
	_apply_visual_tint()
	state_machine.setup(
		self,
		physics_component,
		surface_contact_component,
		wall_detector
	)
	
	if hitbox and attack_profile:
		hitbox.attack_profile = attack_profile
	
	health_component.died.connect(_on_health_component_died)
	
	surface_contact_component.call_deferred("setup", self)

func _physics_process(delta: float) -> void:
	velocity = state_machine.process_physics(delta)
	move_and_slide()

func get_locomotion_profile() -> LocomotionProfile:
	return locomotion_profile

func get_death_profile() -> DeathProfile:
	return death_profile
	
func get_attack_profile() -> AttackProfile:
	return attack_profile

func face_position(target_x: float) -> void:
	var direction_to_target = sign(target_x - global_position.x)
	
	if direction_to_target != 0:
		set_facing_direction(direction_to_target)

func set_facing_direction(direction: float) -> void:
	var facing_sign = sign(direction)
	if facing_sign == 0:
		return

	if is_instance_valid(spine_sprite):
		spine_sprite.scale.x = abs(spine_sprite.scale.x) * facing_sign
	
	if is_instance_valid(wall_detector):
		wall_detector.scale.x = abs(wall_detector.scale.x) * facing_sign
		
	if is_instance_valid(hitbox):
		hitbox.scale.x = abs(hitbox.scale.x) * facing_sign
		
func get_facing_direction() -> float:
	if is_instance_valid(spine_sprite):
		if is_zero_approx(spine_sprite.scale.x):
			return 1.0
		return sign(spine_sprite.scale.x)
	
	if is_zero_approx(scale.x):
		return 1.0
	return sign(scale.x)

func _on_health_component_died():
	state_machine.transition_to("SimpleDeathState")

func set_hitbox_enabled(is_enabled: bool) -> void:
	if not is_instance_valid(hitbox):
		return
	
	hitbox.set_deferred("monitorable", is_enabled)
	hitbox.set_deferred("monitoring", is_enabled)

func _apply_visual_tint():
	if is_instance_valid(spine_sprite) and spine_sprite.normal_material:
		var mat = spine_sprite.normal_material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("tint_color", enemy_tint_color)
			mat.set_shader_parameter("tint_intensity", enemy_tint_intensity)
