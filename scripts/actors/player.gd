class_name Player
extends Actor # <--- Mudança principal aqui

# --- COMPONENTES ESPECÍFICOS DO PLAYER ---
@onready var focus_component: FocusComponent = $FocusComponent
@onready var air_combo_component: AirComboComponent = $AirComboComponent
# SmartTargeting é usado na mobilidade aérea do player
@onready var smart_targeting_component: SmartTargetingComponent = $SmartTargetingComponent

# --- UI & UTILITÁRIOS ---
@onready var hud: HUDController = get_tree().get_first_node_in_group("hud")
@onready var path_target: Node2D = get_parent().get_node("PathTarget")
@onready var hold_input_timer: Timer = $HoldInputTimer
@onready var run_cancel_timer: Timer = $RunCancelTimer

# --- SKILLS E COMBATE DO PLAYER ---
@export_group("Equipped Skills")
@export var skill_x: BaseSkill
@export var skill_y: BaseSkill
@export var skill_a: BaseSkill
@export var skill_b: BaseSkill

# --- PERFIS EXCLUSIVOS DO PLAYER ---
# (O Actor já tem jump_profile, mas o Player tem o running_jump extra)
@export_group("Player Specific Profiles")
@export var running_jump_profile: JumpProfile
@export var dash_profile: DashProfile # Dash puro é do player, DashAttack é comum

func _ready():
	super() # Chama validações do Actor
	
	GameManager.player_node = self
	
	# Setup de componentes
	animation_component.setup(state_machine, spine_sprite)
	spine_sprite.animation_event.connect(_on_spine_event)
	
	# ActionValidator do Player usa Focus e Stamina
	action_cost_validator.setup(stamina_component, focus_component)
	
	# A StateMachine é inicializada aqui passando 'self' (que é um Actor)
	state_machine.initialize(self)
	
	air_mobility_component.setup(self, surface_contact_component, smart_targeting_component)
	surface_contact_component.call_deferred("setup", self)

	if hud:
		await hud.ready
		hud.initialize_hud(self)
		
	attack_executor.setup(self)
	
	hold_input_timer.timeout.connect(_on_hold_input_timer_timeout)
	run_cancel_timer.timeout.connect(_on_run_cancel_timer_timeout)
	surface_contact_component.landed.connect(_on_landed)
	
	_build_skill_dictionary()

func _exit_tree():
	if GameManager.player_node == self:
		GameManager.unregister_player()

func _physics_process(delta: float):
	var walk_direction = Input.get_axis("move_left", "move_right")
	
	# Usa o método utilitário do pai Actor
	_update_facing_direction()
	
	# A State Machine processa a física usando os dados
	velocity = state_machine.process_physics(delta, walk_direction, is_running)

	move_and_slide()
	
func _on_spine_event(_sprite: SpineSprite, _animation_state: SpineAnimationState, _track_entry: SpineTrackEntry, event: SpineEvent):
	var event_name = event.get_data().get_event_name()
	if event_name == "footstep":
		audio_component.play_footstep()

func _build_skill_dictionary():
	if skill_x: _equipped_skills["skill_x"] = skill_x
	if skill_y: _equipped_skills["skill_y"] = skill_y
	if skill_a: _equipped_skills["skill_a"] = skill_a
	if skill_b: _equipped_skills["skill_b"] = skill_b

# --- INPUT HANDLING (Mantido no Player) ---
func _unhandled_input(event: InputEvent):
	
	if event.is_action_pressed("debug_vfx"):
		if vfx_component:
			var spawn_pos = global_position + Vector2(30 * facing_sign, -15)
			var direction = Vector2.RIGHT * facing_sign
			vfx_component.spawn_vfx("blood_splatter", spawn_pos, direction)
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("jump"):
		# Lógica específica: Player tem pulo de corrida
		var profile = running_jump_profile if is_running else jump_profile
		if profile:
			state_machine.on_jump_pressed(profile)
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_released("jump"):
		state_machine.on_jump_released()
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed("dash_run"):
		_send_dash_intention()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("dodge"):
		if not is_on_floor():
			_send_dodge_intention()
		else:
			if not run_cancel_timer.is_stopped():
				run_cancel_timer.stop()
				_send_dodge_intention()
			else:
				hold_input_timer.start()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_released("dodge"):
		if not is_running:
			if not hold_input_timer.is_stopped():
				hold_input_timer.stop()
				_send_dodge_intention()
		else:
			run_cancel_timer.start()
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("attack"):
		var profile_to_use: AttackProfile
		# Combo logic permanece aqui ou movemos para componente depois
		if is_on_floor():
			profile_to_use = combo_component.get_next_attack_profile()
		else:
			# Player usa Air Combo Component
			profile_to_use = air_combo_component.get_next_attack_profile()
		
		if profile_to_use:
			state_machine.on_attack_pressed(profile_to_use)
			
		get_viewport().set_input_as_handled()
		return

	if Input.is_action_pressed("skill_modifier"):
		for action_name in _equipped_skills.keys():
			if event.is_action_pressed(action_name):
				var skill: BaseSkill = _equipped_skills.get(action_name)
				if skill:
					skill.execute(self, state_machine)
				get_viewport().set_input_as_handled()
				return

	if event.is_action_pressed("parry"):
		# get_parry_profile() agora vem do Actor
		var profile = get_parry_profile()
		if profile:
			state_machine.on_parry_pressed(profile)
		get_viewport().set_input_as_handled()
		return

	state_machine.process_input(event)

# --- GETTERS E HELPERS ---
# Removemos getters redundantes que já existem no Actor.
# Mantemos apenas os específicos ou overrides necessários.

func get_dash_profile() -> DashProfile:
	return dash_profile

# O Actor já tem get_jump_profile, mas aqui retornamos o base.
# Se precisar retornar o running profile dinamicamente, podemos sobrescrever.

func _on_hold_input_timer_timeout():
	if Input.is_action_pressed("dodge"):
		is_running = true

func _on_run_cancel_timer_timeout():
	is_running = false

func _on_landed():
	if Input.is_action_pressed("dodge"):
		if hold_input_timer.is_stopped():
			hold_input_timer.start()

func _send_dash_intention():
	var profile = get_dash_profile()
	if profile:
		state_machine.on_dash_pressed(profile)

func _send_dodge_intention():
	var direction = _get_dodge_direction_from_input()
	var profile = _get_dodge_profile_for_direction(direction)
	if profile:
		state_machine.on_dodge_pressed(direction, profile)

func _get_dodge_direction_from_input() -> Vector2:
	var direction = Vector2.ZERO
	if Input.is_action_pressed("move_up"): direction.y = -1
	elif Input.is_action_pressed("move_down"): direction.y = 1
	if Input.is_action_pressed("move_left"): direction.x = -1
	elif Input.is_action_pressed("move_right"): direction.x = 1
	return direction

func _get_dodge_profile_for_direction(direction: Vector2) -> DodgeProfile:
	if direction.y < 0: return up_dodge_profile
	elif direction.y > 0: return down_dodge_profile
	elif direction.x != 0:
		if direction.x * facing_sign > 0: return forward_dodge_profile
		else: return back_dodge_profile
	else: return neutral_dodge_profile
