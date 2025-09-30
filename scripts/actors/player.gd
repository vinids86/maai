class_name Player
extends CharacterBody2D

@onready var state_machine: StateMachine = $StateMachine
@onready var hold_input_timer: Timer = $HoldInputTimer
@onready var run_cancel_timer: Timer = $RunCancelTimer
@onready var attack_executor: AttackExecutor = $AttackExecutor
@onready var combo_component: ComboComponent = $ComboComponent
@onready var skill_combo_component: SkillComboComponent = $SkillComboComponent
@onready var visuals: Node2D = $Visuals

@export_group("Combat Data")
@export var base_poise: float

@export_group("Equipped Skills")
@export var skill_x: BaseSkill
@export var skill_y: BaseSkill
@export var skill_a: BaseSkill
@export var skill_b: BaseSkill

var _equipped_skills: Dictionary = {}

@export_group("Profiles")
@export var finisher_profile: FinisherProfile
@export var parry_profile: ParryProfile
@export var mikiri_riposte_profile: AttackProfile
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

var is_running: bool = false
var facing_sign: int = 1
var facing_locked: bool = false

func _ready():
	attack_executor.setup(self)
	hold_input_timer.timeout.connect(_on_hold_input_timer_timeout)
	run_cancel_timer.timeout.connect(_on_run_cancel_timer_timeout)
	_build_skill_dictionary()

func _physics_process(delta: float):
	var walk_direction = Input.get_axis("move_left", "move_right")
	_update_facing_direction()
	state_machine.process_physics(delta, walk_direction, is_running)
	move_and_slide()

func _build_skill_dictionary():
	if skill_x: _equipped_skills["skill_x"] = skill_x
	if skill_y: _equipped_skills["skill_y"] = skill_y
	if skill_a: _equipped_skills["skill_a"] = skill_a
	if skill_b: _equipped_skills["skill_b"] = skill_b

func _update_facing_direction():
	if visuals:
		visuals.scale.x = facing_sign

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("dodge_run"):
		if not run_cancel_timer.is_stopped():
			run_cancel_timer.stop()
			_send_dodge_intention()
		else:
			hold_input_timer.start()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_released("dodge_run"):
		if not is_running:
			if not hold_input_timer.is_stopped():
				hold_input_timer.stop()
				_send_dodge_intention()
		else:
			run_cancel_timer.start()
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("attack"):
		var profile = combo_component.get_next_attack_profile()
		if profile:
			state_machine.on_attack_pressed(profile)
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

func _on_hold_input_timer_timeout():
	if Input.is_action_pressed("dodge_run"):
		is_running = true

func _on_run_cancel_timer_timeout():
	is_running = false

func _send_dodge_intention():
	var direction = _get_dodge_direction_from_input()
	var profile = _get_dodge_profile_for_direction(direction)
	if profile:
		state_machine.on_dodge_pressed(direction, profile)

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
