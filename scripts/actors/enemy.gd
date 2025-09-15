class_name Enemy
extends CharacterBody2D

@onready var state_machine: StateMachine = $StateMachine
@onready var ai_controller: AIController = $AIController
@onready var health_component: HealthComponent = $HealthComponent
@onready var stamina_component: StaminaComponent = $StaminaComponent
@onready var status_ui: EnemyStatusUI = $EnemyStatusUI

@export var visual_node: CanvasItem

@export_group("Combat Data")
@export var attack_set: AttackSet
@export var finisher_profile: FinisherProfile
@export var parry_profile: ParryProfile
@export var block_stun_profile: BlockStunProfile
@export var stagger_profile: StaggerProfile
@export var parried_profile: ParriedProfile
@export var guard_broken_profile: GuardBrokenProfile
@export var locomotion_profile: LocomotionProfile

@export_group("Dodge Profiles")
@export var neutral_dodge_profile: DodgeProfile
@export var forward_dodge_profile: DodgeProfile
@export var back_dodge_profile: DodgeProfile
@export var up_dodge_profile: DodgeProfile
@export var down_dodge_profile: DodgeProfile

var material_ref: ShaderMaterial
var facing_sign: int = 1
var facing_locked: bool = false
var combo_index: int = 0

func _ready():
	assert(visual_node != null, "Enemy: O nó visual (visual_node) não foi atribuído no Inspetor.")
	assert(health_component != null, "Enemy: Nó HealthComponent não encontrado.")
	assert(stamina_component != null, "Enemy: Nó StaminaComponent não encontrado.")
	assert(status_ui != null, "Enemy: Nó EnemyStatusUI não encontrado.")
	
	if visual_node.material is ShaderMaterial:
		material_ref = visual_node.material
		
	health_component.health_changed.connect(status_ui.update_health)
	stamina_component.stamina_changed.connect(status_ui.update_stamina)

func _physics_process(delta: float):
	var walk_direction = ai_controller.get_walk_direction()
	var is_running = ai_controller.is_running()
	
	state_machine.process_physics(delta, walk_direction, is_running)
	move_and_slide()
	
func reset_combo_chain():
	combo_index = 0
	
func advance_combo_chain():
	combo_index += 1
	
func get_next_attack_in_combo() -> AttackProfile:
	if not attack_set or attack_set.attacks.is_empty():
		return null

	if combo_index >= attack_set.attacks.size():
		return null
	
	var profile = attack_set.attacks[combo_index]
	combo_index += 1
	return profile

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
