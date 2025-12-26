class_name Actor
extends CharacterBody2D

# --- REFERÊNCIAS GLOBAIS (O "Corpo" do Ator) ---
# Usamos @export para permitir injeção via Inspector, eliminando o acoplamento por nomes de nós ($Node).
@export_group("Core Components")
@export var state_machine: StateMachine
@export var spine_sprite: SpineSprite
@export var animation_component: AnimationComponent
@export var physics_component: PhysicsComponent
@export var health_component: HealthComponent
@export var stamina_component: StaminaComponent
@export var action_cost_validator: ActionCostValidator
@export var audio_component: AudioComponent
@export var vfx_component: VFXComponent

@export_group("Combat Components")
@export var attack_executor: AttackExecutor
@export var counter_executor_component: CounterExecutorComponent
@export var combo_component: ComboComponent
@export var skill_combo_component: SkillComboComponent
@export var hitbox_component: Hitbox # Assumindo que você tem/terá hitboxes padronizadas
@export var hurtbox_component: Hurtbox

@export_group("Movement & Environment")
@export var air_mobility_component: AirMobilityComponent
@export var path_follower_component: PathFollowerComponent
@export var buffer_component: BufferComponent
@export var surface_contact_component: SurfaceContactComponent
@export var wall_detector: WallDetectorComponent

# --- CONFIGURAÇÕES GERAIS ---
@export_group("Combat Data")
@export var base_poise: float

@export_group("Profiles - Movement")
@export var locomotion_profile: LocomotionProfile
@export var jump_profile: JumpProfile
@export var wall_slide_profile: WallSlideProfile
# Nota: Player tem running_jump, Enemy não. Mantemos o básico aqui.

@export_group("Profiles - Combat")
@export var finisher_profile: FinisherProfile
@export var parry_profile: ParryProfile
@export var riposte_profile: AttackProfile
@export var dash_attack_profile: AttackProfile 

@export_group("Profiles - Reaction")
@export var block_stun_profile: BlockStunProfile
@export var stagger_profile: StaggerProfile
@export var parried_profile: ParriedProfile
@export var guard_broken_profile: GuardBrokenProfile
@export var death_profile: DeathProfile

@export_group("Profiles - Dodge")
@export var neutral_dodge_profile: DodgeProfile
@export var forward_dodge_profile: DodgeProfile
@export var back_dodge_profile: DodgeProfile
@export var up_dodge_profile: DodgeProfile
@export var down_dodge_profile: DodgeProfile

# --- VARIÁVEIS DE ESTADO COMUNS ---
var facing_sign: int = 1
var facing_locked: bool = false
var is_running: bool = false # Comum para lógica de física
var _equipped_skills: Dictionary = {}

# --- CICLO DE VIDA (Mínimo, para não conflitar ainda) ---
func _ready() -> void:
	# Validação de segurança para garantir que o Hub está configurado
	if not state_machine: push_warning("Actor: StateMachine não atribuída no Inspector em " + name)
	if not physics_component: push_warning("Actor: PhysicsComponent não atribuído no Inspector em " + name)

# --- API PÚBLICA (GETTERS PARA A STATE MACHINE) ---
# Isso permite que a StateMachine acesse dados sem saber se é Player ou Enemy

func get_locomotion_profile() -> LocomotionProfile: return locomotion_profile
func get_jump_profile() -> JumpProfile: return jump_profile
func get_wall_slide_profile() -> WallSlideProfile: return wall_slide_profile
func get_finisher_profile() -> FinisherProfile: return finisher_profile
func get_parry_profile() -> ParryProfile: return parry_profile
func get_riposte_profile() -> AttackProfile: return riposte_profile
func get_block_stun_profile() -> BlockStunProfile: return block_stun_profile
func get_stagger_profile() -> StaggerProfile: return stagger_profile
func get_parried_profile() -> ParriedProfile: return parried_profile
func get_guard_broken_profile() -> GuardBrokenProfile: return guard_broken_profile
func get_death_profile() -> DeathProfile: return death_profile
func get_finisher_attack_profile() -> AttackProfile: return finisher_profile.attack_profile

# --- UTILITÁRIOS ---

func reset_air_actions() -> void:
	if air_mobility_component:
		air_mobility_component.reset_resources()

func _update_facing_direction():
	if is_instance_valid(spine_sprite):
		spine_sprite.scale.x = abs(spine_sprite.scale.x) * facing_sign
