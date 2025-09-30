class_name Enemy
extends CharacterBody2D

@onready var state_machine: StateMachine = $StateMachine
@onready var ai_controller: AIController = $AIController
@onready var health_component: HealthComponent = $HealthComponent
@onready var stamina_component: StaminaComponent = $StaminaComponent
@onready var status_ui: EnemyStatusUI = $EnemyStatusUI
@onready var attack_executor: AttackExecutor = $AttackExecutor
@onready var combo_component: ComboComponent = $ComboComponent
@onready var skill_combo_component: SkillComboComponent = $SkillComboComponent
@onready var detection_area: Area2D = $DetectionArea
@onready var visuals: Node2D = $Visuals

@export_group("Equipped Skills")
@export var skill_x: BaseSkill
@export var skill_y: BaseSkill
@export var skill_a: BaseSkill
@export var skill_b: BaseSkill

@export_group("Combat Data")
@export var finisher_profile: FinisherProfile
@export var parry_profile: ParryProfile
@export var mikiri_riposte_profile: AttackProfile
@export var block_stun_profile: BlockStunProfile
@export var stagger_profile: StaggerProfile
@export var parried_profile: ParriedProfile
@export var guard_broken_profile: GuardBrokenProfile
@export var locomotion_profile: LocomotionProfile
@export var base_poise: float

@export_group("Dodge Profiles")
@export var neutral_dodge_profile: DodgeProfile
@export var forward_dodge_profile: DodgeProfile
@export var back_dodge_profile: DodgeProfile
@export var up_dodge_profile: DodgeProfile
@export var down_dodge_profile: DodgeProfile

var _equipped_skills: Dictionary = {}
var material_ref: ShaderMaterial
var facing_sign: int = 1
var facing_locked: bool = false

func _ready():
	_build_skill_dictionary()
	
	assert(visuals != null, "Enemy: Nó 'Visuals' (Node2D) não encontrado como filho.")
	assert(health_component != null, "Enemy: Nó HealthComponent não encontrado.")
	assert(stamina_component != null, "Enemy: Nó StaminaComponent não encontrado.")
	assert(status_ui != null, "Enemy: Nó EnemyStatusUI não encontrado.")
	assert(detection_area != null, "Enemy: Nó 'DetectionArea' (Area2D) não encontrado como filho.")
	
	attack_executor.setup(self)

	if visuals.get_child_count() > 0 and visuals.get_child(0).material is ShaderMaterial:
		material_ref = visuals.get_child(0).material
		
	health_component.health_changed.connect(status_ui.update_health)
	stamina_component.stamina_changed.connect(status_ui.update_stamina)

func _physics_process(delta: float):
	var walk_direction = ai_controller.get_walk_direction()
	var is_running = ai_controller.is_running()
	
	_update_facing_direction()
	
	state_machine.process_physics(delta, walk_direction, is_running)
	move_and_slide()

func _build_skill_dictionary():
	if skill_x: _equipped_skills["skill_x"] = skill_x
	if skill_y: _equipped_skills["skill_y"] = skill_y
	if skill_a: _equipped_skills["skill_a"] = skill_a
	if skill_b: _equipped_skills["skill_b"] = skill_b

func get_skill(action_name: String) -> BaseSkill:
	return _equipped_skills.get(action_name)

func _update_facing_direction():
	if visuals:
		visuals.scale.x = facing_sign
	if detection_area:
		detection_area.scale.x = facing_sign

func get_mikiri_riposte_profile() -> AttackProfile:
	return mikiri_riposte_profile
	
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

func flash_red():
	if not material_ref:
		push_warning("Enemy: Nenhum ShaderMaterial encontrado no nó visual para o efeito de flash.")
		return
		
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
	
	tween.tween_property(material_ref, "shader_parameter/flash_modifier", 1.0, 0.0).from(1.0).set_delay(0.05)
	tween.tween_property(material_ref, "shader_parameter/flash_modifier", 0.0, 0.15)
