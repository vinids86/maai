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

var is_sheathed: bool = true

func _ready():
	super() 
	
	GameManager.register_player(self)
	
	# Conexão para gerenciar a postura (sheathed/unsheathed) via State Machine
	state_machine.transitioned.connect(_on_state_machine_transitioned)
	
	# Conexão Global de Tensão de Batalha (Novo Sistema)
	GameManager.combat_state_changed.connect(_on_combat_state_changed)
	
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
	
	velocity = logic_velocity

	move_and_slide()

func _build_skill_dictionary():
	if skill_x: _equipped_skills["skill_x"] = skill_x
	if skill_y: _equipped_skills["skill_y"] = skill_y
	if skill_a: _equipped_skills["skill_a"] = skill_a
	if skill_b: _equipped_skills["skill_b"] = skill_b

# --- GETTERS ---

func get_dash_profile() -> DashProfile:
	return dash_profile

func get_equipped_skills() -> Dictionary:
	return _equipped_skills

# Lógica de seleção de perfil baseada na postura (sobrescreve Actor)
func get_locomotion_profile() -> LocomotionProfile:
	if is_sheathed and exploration_locomotion_profile:
		return exploration_locomotion_profile
	return locomotion_profile

# Listener da StateMachine para atualizar a postura (Ações diretas do jogador)
func _on_state_machine_transitioned(_from_state: State, to_state: State):
	match to_state.name:
		"DashState":
			is_sheathed = true 
		"AttackState", "ParryState", "AirAttackState":
			is_sheathed = false

# Callback global de mudança de tensão
func _on_combat_state_changed(is_in_combat: bool) -> void:
	if not is_in_combat:
		sheath_weapon()

func sheath_weapon() -> void:
	if not is_sheathed:
		is_sheathed = true
		print("Player: Arma embainhada (Fim de Combate)")
