class_name Enemy
extends Actor # <--- Mudança principal aqui

# --- COMPONENTES ESPECÍFICOS DO INIMIGO ---
@onready var ai_controller: AIController = $AIController
@onready var status_ui: EnemyStatusUI = $EnemyStatusUI
@onready var detection_area: Area2D = $DetectionArea
@onready var path_target: Node2D = get_parent().get_node("PathTarget")

# --- SKILLS EXTRA ---
@export_group("Equipped Skills")
@export var skill_x: BaseSkill
@export var skill_y: BaseSkill
@export var skill_a: BaseSkill
@export var skill_b: BaseSkill
@export var skill_z: BaseSkill # Inimigos podem ter skills extras (Z)

# --- VISUAL IDENTITY ---
@export_group("Visual Identity")
@export var enemy_tint_color: Color = Color.WHITE
@export_range(0.0, 1.0) var enemy_tint_intensity: float = 0.0

var air_jumps_left: int = 0
var air_dash_used: bool = false
var has_locked_air_pool: bool = false
var _target_detected: Node2D = null

func _ready():
	super() # Chama validações do Actor
	
	_build_skill_dictionary()
	_update_facing_direction()
	
	animation_component.setup(state_machine, spine_sprite)
	_apply_visual_tint()
		
	# Inimigo geralmente não usa FocusComponent, então passamos null no segundo arg
	action_cost_validator.setup(stamina_component, null)
	
	state_machine.initialize(self)
	attack_executor.setup(self)

	# Conecta UI de status (Vida/Stamina)
	if health_component and status_ui:
		health_component.health_changed.connect(status_ui.update_health)
	if stamina_component and status_ui:
		stamina_component.stamina_changed.connect(status_ui.update_stamina)
	
	surface_contact_component.call_deferred("setup", self)
	
	if detection_area:
		detection_area.body_entered.connect(_on_detection_entered)
		detection_area.body_exited.connect(_on_detection_exited)

func _physics_process(delta: float):
	# Lógica de Input vinda da IA
	var walk_direction = ai_controller.get_walk_direction()
	var is_running_ia = ai_controller.is_running()
	
	# Lógica de Facing baseada no alvo
	if not facing_locked and is_instance_valid(_target_detected) and not (state_machine.current_state is DeathState):
		var direction_to_target = _target_detected.global_position.x - global_position.x
		if abs(direction_to_target) > 10.0: 
			facing_sign = sign(direction_to_target)
	
	_update_facing_direction()
	
	if is_instance_valid(path_target):
		path_target.global_position = self.global_position
	
	# Processa movimento
	velocity = state_machine.process_physics(delta, walk_direction, is_running_ia)
	move_and_slide()

func _on_detection_entered(body: Node2D):
	if body is Player:
		_target_detected = body

func _on_detection_exited(body: Node2D):
	if body == _target_detected:
		_target_detected = null

func _build_skill_dictionary():
	# Popula o dicionário herdado do Actor
	if skill_x: _equipped_skills["skill_x"] = skill_x
	if skill_y: _equipped_skills["skill_y"] = skill_y
	if skill_a: _equipped_skills["skill_a"] = skill_a
	if skill_b: _equipped_skills["skill_b"] = skill_b
	if skill_z: _equipped_skills["skill_z"] = skill_z

func get_skill(action_name: String) -> BaseSkill:
	return _equipped_skills.get(action_name)

# --- OVERRIDES DE UTILITÁRIOS ---

func _update_facing_direction():
	super() # Chama o base (vira o sprite)
	# Adiciona lógica específica do inimigo (Detection Area)
	if detection_area:
		detection_area.scale.x = facing_sign

func _apply_visual_tint():
	if is_instance_valid(spine_sprite) and spine_sprite.normal_material:
		var mat = spine_sprite.normal_material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("tint_color", enemy_tint_color)
			mat.set_shader_parameter("tint_intensity", enemy_tint_intensity)

# Getters removidos pois já existem no Actor e retornam as variáveis herdadas
