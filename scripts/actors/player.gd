class_name Player
extends Actor

# --- COMPONENTES ESPECÍFICOS DO PLAYER ---
@onready var focus_component: FocusComponent = $FocusComponent
@onready var air_combo_component: AirComboComponent = $AirComboComponent
@onready var smart_targeting_component: SmartTargetingComponent = $SmartTargetingComponent
@onready var input_component: PlayerInputComponent = $PlayerInputComponent

# --- UI & UTILITÁRIOS ---
@onready var hud: HUDController = get_tree().get_first_node_in_group("hud")
@onready var path_target: Node2D = get_parent().get_node("PathTarget")

# --- SKILLS E COMBATE DO PLAYER ---
@export_group("Equipped Skills")
@export var skill_x: BaseSkill
@export var skill_y: BaseSkill
@export var skill_a: BaseSkill
@export var skill_b: BaseSkill

# --- PERFIS EXCLUSIVOS DO PLAYER ---
@export_group("Player Specific Profiles")
@export var running_jump_profile: JumpProfile
@export var dash_profile: DashProfile

func _ready():
	super() # Chama validações do Actor
	
	GameManager.player_node = self
	
	# Setup de componentes existentes
	animation_component.setup(state_machine, spine_sprite)
	
	action_cost_validator.setup(stamina_component, focus_component)
	state_machine.initialize(self)
	
	air_mobility_component.setup(self, surface_contact_component, smart_targeting_component)
	surface_contact_component.call_deferred("setup", self)

	if hud:
		await hud.ready
		hud.initialize_hud(self)
		
	attack_executor.setup(self)
	
	_build_skill_dictionary()
	
	input_component.setup(self)
	
func _exit_tree():
	if GameManager.player_node == self:
		GameManager.unregister_player()

func _physics_process(delta: float):
	var walk_direction = Input.get_axis("move_left", "move_right")
	
	_update_facing_direction()
	
	var logic_velocity = state_machine.process_physics(delta, walk_direction, is_running)
	
	var root_motion_states = ["AttackState"]
	
	var current_state_name = ""
	if state_machine.current_state:
		current_state_name = state_machine.current_state.name
	
	velocity = logic_velocity

	move_and_slide()

func process_root_motion(delta: float):
	var skeleton = spine_sprite.get_skeleton()
	if not skeleton: return
	
	var root_bone = skeleton.find_bone("root")
	var motion_x = root_bone.get_x()
	var motion_y = root_bone.get_y()
	
	# Zera o osso visualmente para não "duplicar" o movimento
	root_bone.set_x(0)
	root_bone.set_y(0)
	
	if motion_x == 0 and motion_y == 0:
		velocity.x = 0
		return

	# CORREÇÃO PRINCIPAL:
	# Multiplicamos pela escala do Nó (se você diminuiu o boneco na cena)
	# E pela escala do Esqueleto (se o boneco estiver espelhado/virado)
	var final_scale_x = spine_sprite.scale.x * skeleton.get_scale_x()
	var final_scale_y = spine_sprite.scale.y * skeleton.get_scale_y()
	
	# Aplica o movimento ajustado pela escala e pelo seu multiplicador manual
	velocity.x = (motion_x * final_scale_x * 0.3) / delta
	
	# Para o Y, geralmente queremos manter a gravidade se o movimento da animação for pífio
	if abs(motion_y) > 1.0: # Só aplica se mover mais que 1 pixel no Spine
		velocity.y = (motion_y * final_scale_y * 0.3) / delta

func _build_skill_dictionary():
	if skill_x: _equipped_skills["skill_x"] = skill_x
	if skill_y: _equipped_skills["skill_y"] = skill_y
	if skill_a: _equipped_skills["skill_a"] = skill_a
	if skill_b: _equipped_skills["skill_b"] = skill_b

# --- GETTERS NECESSÁRIOS PARA O INPUT COMPONENT ---

func get_dash_profile() -> DashProfile:
	return dash_profile

func get_equipped_skills() -> Dictionary:
	return _equipped_skills
