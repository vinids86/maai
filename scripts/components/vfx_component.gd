class_name VFXComponent
extends Node2D

@export var vfx_library: Dictionary[String, PackedScene] = {}
@export var blood_effect_delay: float = 0.1

var actor: Node2D
var health_component: HealthComponent
var _previous_health: float = 0.0

func _ready():
	actor = get_parent()
	
	health_component = actor.get_node_or_null("HealthComponent")
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		_previous_health = health_component.max_health

	if ImpactResolver:
		ImpactResolver.impact_resolved.connect(_on_impact_resolved)

func _on_health_changed(current_health: float, _max_health: float):
	if current_health < _previous_health:
		_play_blood_effect_with_delay()

	_previous_health = current_health

func _play_blood_effect_with_delay():
	await get_tree().create_timer(blood_effect_delay).timeout
	
	if not is_instance_valid(actor):
		return
		
	var facing_sign = actor.facing_sign if "facing_sign" in actor else 1
	var spawn_pos = actor.global_position + Vector2(0, 0)
	var direction = Vector2.RIGHT * -facing_sign
	spawn_vfx("blood_splatter", spawn_pos, direction)

func _on_impact_resolved(result: ContactResult):
	if result.defender_node != actor:
		return
	
	var vfx_name = ""
	var vfx_pos = Vector2.ZERO
	var vfx_dir = Vector2.ZERO
	var facing_sign = actor.facing_sign if "facing_sign" in actor else 1

	match result.defender_outcome:
		ContactResult.DefenderOutcome.PARRY_SUCCESS:
			vfx_name = "clash_spark"
			vfx_pos = actor.global_position + Vector2(30 * facing_sign, -15)
			vfx_dir = Vector2.LEFT * facing_sign

		ContactResult.DefenderOutcome.BLOCKED:
			vfx_name = "block_spark"
			vfx_pos = actor.global_position + Vector2(30 * facing_sign, -15)
			vfx_dir = Vector2.LEFT * facing_sign
		
		ContactResult.DefenderOutcome.DODGED:
			vfx_name = "dodge_dust"
			vfx_pos = actor.global_position
			vfx_dir = Vector2.DOWN
	
	if not vfx_name.is_empty():
		spawn_vfx(vfx_name, vfx_pos, vfx_dir)

func spawn_vfx(vfx_name: String, spawn_position: Vector2, direction: Vector2):
	if not vfx_library.has(vfx_name):
		return

	var vfx_scene: PackedScene = vfx_library.get(vfx_name)
	if not vfx_scene:
		return
		
	var vfx_instance = vfx_scene.instantiate()
	get_tree().current_scene.add_child(vfx_instance)
	
	vfx_instance.global_position = spawn_position
	if direction != Vector2.ZERO:
		vfx_instance.rotation = direction.angle()
	
	vfx_instance.emitting = true
	vfx_instance.finished.connect(vfx_instance.queue_free.bind())
