class_name Player
extends CharacterBody2D

@onready var state_machine: StateMachine = $StateMachine
@onready var spine_sprite: SpineSprite = $SpineSprite
@onready var animation_listener: AnimationListener = $AnimationListener
@onready var health_component: HealthComponent = $HealthComponent
@onready var stamina_component: StaminaComponent = $StaminaComponent
@onready var focus_component: FocusComponent = $FocusComponent
@onready var physics_component: PhysicsComponent = $PhysicsComponent
@onready var path_follower_component: PathFollowerComponent = $PathFollowerComponent
@onready var buffer_component: BufferComponent = $BufferComponent
@onready var surface_contact_component: SurfaceContactComponent = $SurfaceContactComponent
@onready var wall_detector: WallDetectorComponent = $WallDetectorComponent
@onready var hold_input_timer: Timer = $HoldInputTimer
@onready var run_cancel_timer: Timer = $RunCancelTimer
@onready var attack_executor: AttackExecutor = $AttackExecutor
@onready var combo_component: ComboComponent = $ComboComponent
@onready var air_combo_component: AirComboComponent = $AirComboComponent
@onready var skill_combo_component: SkillComboComponent = $SkillComboComponent
@onready var hud: HUDController = get_tree().get_first_node_in_group("hud")
@onready var path_target: Node2D = get_parent().get_node("PathTarget")
@onready var action_cost_validator: ActionCostValidator = $ActionCostValidator

# ... (suas propriedades @export e variáveis continuam aqui) ...
@export_group("Combat Data")
@export var base_poise: float

@export_group("Equipped Skills")
@export var skill_x: BaseSkill
@export var skill_y: BaseSkill
@export var skill_a: BaseSkill
@export var skill_b: BaseSkill

var _equipped_skills: Dictionary = {}

@export_group("Profiles")
@export var jump_profile: JumpProfile
@export var running_jump_profile: JumpProfile
@export var finisher_profile: FinisherProfile
@export var parry_profile: ParryProfile
@export var riposte_profile: AttackProfile
@export var mikiri_riposte_profile: AttackProfile
@export var block_stun_profile: BlockStunProfile
@export var stagger_profile: StaggerProfile
@export var parried_profile: ParriedProfile
@export var guard_broken_profile: GuardBrokenProfile
@export var locomotion_profile: LocomotionProfile
@export var countered_profile: CounteredProfile
@export var death_profile: DeathProfile
@export var dash_profile: DashProfile
@export var dash_attack_profile: AttackProfile
@export var wall_slide_profile: WallSlideProfile

@export_group("Dodge Profiles")
@export var neutral_dodge_profile: DodgeProfile
@export var forward_dodge_profile: DodgeProfile
@export var back_dodge_profile: DodgeProfile
@export var up_dodge_profile: DodgeProfile
@export var down_dodge_profile: DodgeProfile

var is_running: bool = false
var facing_sign: int = 1
var facing_locked: bool = false

var air_jumps_left: int = 0
var air_dash_used: bool = false
var has_locked_air_pool: bool = false
var last_left_ground_ms: int = -1

func _ready():
	GameManager.player_node = self
	
	animation_listener.setup(state_machine, spine_sprite)
	
	action_cost_validator.setup(stamina_component, focus_component)
	state_machine.setup(
		self,
		physics_component,
		path_follower_component,
		buffer_component,
		action_cost_validator,
		surface_contact_component,
		wall_detector
	)

	surface_contact_component.call_deferred("setup", self)

	if hud:
		await hud.ready
		hud.initialize_hud(self)
	attack_executor.setup(self)
	hold_input_timer.timeout.connect(_on_hold_input_timer_timeout)
	run_cancel_timer.timeout.connect(_on_run_cancel_timer_timeout)
	surface_contact_component.landed.connect(_on_landed)
	_build_skill_dictionary()

func _update_facing_direction():
	if is_instance_valid(spine_sprite):
		spine_sprite.scale.x = abs(spine_sprite.scale.x) * facing_sign

func _exit_tree():
	if GameManager.player_node == self:
		GameManager.unregister_player()

func _physics_process(delta: float):
	var walk_direction = Input.get_axis("move_left", "move_right")
	_update_facing_direction()
	
	velocity = state_machine.process_physics(delta, walk_direction, is_running)

	move_and_slide()

func _build_skill_dictionary():
	if skill_x: _equipped_skills["skill_x"] = skill_x
	if skill_y: _equipped_skills["skill_y"] = skill_y
	if skill_a: _equipped_skills["skill_a"] = skill_a
	if skill_b: _equipped_skills["skill_b"] = skill_b

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("jump"):
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
		if is_on_floor():
			profile_to_use = combo_component.get_next_attack_profile()
		else:
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
		var profile = get_parry_profile()
		if profile:
			state_machine.on_parry_pressed(profile)
		get_viewport().set_input_as_handled()
		return

	state_machine.process_input(event)

func reset_air_actions():
	if jump_profile:
		air_jumps_left = jump_profile.max_air_jumps
	air_dash_used = false
	has_locked_air_pool = true

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

func get_jump_profile() -> JumpProfile:
	return jump_profile

func get_dash_profile() -> DashProfile:
	return dash_profile

func get_riposte_profile() -> AttackProfile:
	return riposte_profile

func get_mikiri_riposte_profile() -> AttackProfile:
	return mikiri_riposte_profile

func get_finisher_profile() -> FinisherProfile:
	return finisher_profile

func get_finisher_attack_profile() -> AttackProfile:
	if not finisher_profile: return null
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
	
func get_countered_profile() -> CounteredProfile:
	return countered_profile
	
func get_death_profile() -> DeathProfile:
	return death_profile
	
func get_wall_slide_profile() -> WallSlideProfile:
	return wall_slide_profile

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
