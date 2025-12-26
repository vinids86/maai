class_name Enemy
extends CharacterBody2D

@onready var state_machine: StateMachine = $StateMachine
@onready var spine_sprite: SpineSprite = $SpineSprite
@onready var animation_component: AnimationComponent = $AnimationComponent
@onready var air_mobility_component: AirMobilityComponent = $AirMobilityComponent
@onready var audio_component: AudioComponent = $AudioComponent
@onready var ai_controller: AIController = $AIController
@onready var health_component: HealthComponent = $HealthComponent
@onready var stamina_component: StaminaComponent = $StaminaComponent
@onready var status_ui: EnemyStatusUI = $EnemyStatusUI
@onready var attack_executor: AttackExecutor = $AttackExecutor
@onready var counter_executor_component: CounterExecutorComponent = $CounterExecutorComponent
@onready var combo_component: ComboComponent = $ComboComponent
@onready var skill_combo_component: SkillComboComponent = $SkillComboComponent
@onready var detection_area: Area2D = $DetectionArea
@onready var path_target: Node2D = get_parent().get_node("PathTarget")
@onready var action_cost_validator: ActionCostValidator = $ActionCostValidator
@onready var physics_component: PhysicsComponent = $PhysicsComponent
@onready var path_follower_component: PathFollowerComponent = $PathFollowerComponent
@onready var buffer_component: BufferComponent = $BufferComponent
@onready var surface_contact_component: SurfaceContactComponent = $SurfaceContactComponent
@onready var wall_detector: WallDetectorComponent = $WallDetectorComponent

@export_group("Settings")
@export var facing_sign: int = -1 

@export_group("Equipped Skills")
@export var skill_x: BaseSkill
@export var skill_y: BaseSkill
@export var skill_a: BaseSkill
@export var skill_b: BaseSkill
@export var skill_z: BaseSkill

@export_group("Combat Data")
@export var base_poise: float
@export var jump_profile: JumpProfile
@export var finisher_profile: FinisherProfile
@export var parry_profile: ParryProfile
@export var riposte_profile: AttackProfile
@export var block_stun_profile: BlockStunProfile
@export var stagger_profile: StaggerProfile
@export var parried_profile: ParriedProfile
@export var guard_broken_profile: GuardBrokenProfile
@export var locomotion_profile: LocomotionProfile
@export var death_profile: DeathProfile
@export var dash_attack_profile: AttackProfile
@export var wall_slide_profile: WallSlideProfile

@export_group("Dodge Profiles")
@export var neutral_dodge_profile: DodgeProfile
@export var forward_dodge_profile: DodgeProfile
@export var back_dodge_profile: DodgeProfile
@export var up_dodge_profile: DodgeProfile
@export var down_dodge_profile: DodgeProfile

@export_group("Visual Identity")
@export var enemy_tint_color: Color = Color.WHITE
@export_range(0.0, 1.0) var enemy_tint_intensity: float = 0.0

var _equipped_skills: Dictionary = {}
var facing_locked: bool = false

var air_jumps_left: int = 0
var air_dash_used: bool = false
var has_locked_air_pool: bool = false
var _target_detected: Node2D = null

func _ready():
	_build_skill_dictionary()
	
	_update_facing_direction()
	
	animation_component.setup(state_machine, spine_sprite)
	
	_apply_visual_tint()
	
	spine_sprite.animation_event.connect(_on_spine_event)
	
	action_cost_validator.setup(stamina_component, null)
	state_machine.initialize(self)
	
	attack_executor.setup(self)

	health_component.health_changed.connect(status_ui.update_health)
	stamina_component.stamina_changed.connect(status_ui.update_stamina)
	
	surface_contact_component.call_deferred("setup", self)
	if detection_area:
		detection_area.body_entered.connect(_on_detection_entered)
		detection_area.body_exited.connect(_on_detection_exited)

func _physics_process(delta: float):
	var walk_direction = ai_controller.get_walk_direction()
	var is_running = ai_controller.is_running()
	
	if not facing_locked and is_instance_valid(_target_detected) and not (state_machine.current_state is DeathState):
		var direction_to_target = _target_detected.global_position.x - global_position.x
		if abs(direction_to_target) > 10.0: 
			facing_sign = sign(direction_to_target)
	
	_update_facing_direction()
	
	if is_instance_valid(path_target):
		path_target.global_position = self.global_position
	
	velocity = state_machine.process_physics(delta, walk_direction, is_running)
	move_and_slide()

func _on_spine_event(_sprite: SpineSprite, _animation_state: SpineAnimationState, _track_entry: SpineTrackEntry, event: SpineEvent):
	var event_name = event.get_data().get_event_name()
	
	match event_name:
		"footstep":
			if audio_component:
				audio_component.play_footstep()

func _on_detection_entered(body: Node2D):
	if body is Player:
		_target_detected = body

func _on_detection_exited(body: Node2D):
	if body == _target_detected:
		_target_detected = null

func _build_skill_dictionary():
	if skill_x: _equipped_skills["skill_x"] = skill_x
	if skill_y: _equipped_skills["skill_y"] = skill_y
	if skill_a: _equipped_skills["skill_a"] = skill_a
	if skill_b: _equipped_skills["skill_b"] = skill_b
	if skill_z: _equipped_skills["skill_z"] = skill_z

func get_skill(action_name: String) -> BaseSkill:
	return _equipped_skills.get(action_name)

func _update_facing_direction():
	if is_instance_valid(spine_sprite):
		spine_sprite.scale.x = abs(spine_sprite.scale.x) * facing_sign
	if detection_area:
		detection_area.scale.x = facing_sign

func get_riposte_profile() -> AttackProfile:
	return riposte_profile
	
func get_finisher_profile() -> FinisherProfile:
	return finisher_profile

func get_finisher_attack_profile() -> AttackProfile:
	if not finisher_profile:
		return null
	return finisher_profile.attack_profile

func get_parry_profile() -> ParryProfile:
	return parry_profile
	
func get_block_stun_profile() -> BlockStunProfile:
	return block_stun_profile
	
func get_stagger_profile() -> StaggerProfile:
	return stagger_profile
	
func get_parried_profile() -> ParriedProfile:
	return parried_profile
	
func get_guard_broken_profile() -> GuardBrokenProfile:
	return guard_broken_profile

func get_locomotion_profile() -> LocomotionProfile:
	return locomotion_profile

func get_death_profile() -> DeathProfile:
	return death_profile

func get_wall_slide_profile() -> WallSlideProfile:
	return wall_slide_profile

func get_jump_profile() -> JumpProfile:
	return jump_profile
	
func reset_air_actions() -> void:
	air_mobility_component.reset_resources()

func _apply_visual_tint():
	if is_instance_valid(spine_sprite) and spine_sprite.normal_material:
		var mat = spine_sprite.normal_material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("tint_color", enemy_tint_color)
			mat.set_shader_parameter("tint_intensity", enemy_tint_intensity)
