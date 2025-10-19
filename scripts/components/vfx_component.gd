class_name VFXComponent
extends Node2D

@export var vfx_library: Dictionary[String, PackedScene] = {}

var owner_node: Node2D

func _ready():
	owner_node = get_parent()
	
	if ImpactResolver:
		ImpactResolver.impact_resolved.connect(_on_impact_resolved)
	else:
		printerr("VFXComponent não conseguiu se conectar ao ImpactResolver.")

func _on_impact_resolved(result: ContactResult):
	if result.attacker_node != owner_node and result.defender_node != owner_node:
		return
	
	var vfx_name = ""
	var vfx_pos = position

	if result.defender_node == owner_node:
		match result.defender_outcome:
			ContactResult.DefenderOutcome.PARRY_SUCCESS:
				vfx_name = "clash_spark"
			
			ContactResult.DefenderOutcome.DODGED:
				vfx_name = "dodge_dust"
				vfx_pos = owner_node.global_position
		
	if result.attacker_node == owner_node:
		match result.attacker_outcome:
			ContactResult.AttackerOutcome.PARRIED:
				pass

	if not vfx_name.is_empty():
		owner_node.global_position + Vector2(30 * owner_node.facing_sign, -15)
		spawn_vfx(vfx_name, global_position + Vector2(30 * owner_node.facing_sign, -15))


func spawn_vfx(vfx_name: String, spawn_position: Vector2):
	if not vfx_library.has(vfx_name):
		printerr("VFXComponent: Efeito não encontrado: ", vfx_name)
		return

	var vfx_scene: PackedScene = vfx_library.get(vfx_name)
	if not vfx_scene:
		printerr("VFXComponent: Cena para '", vfx_name, "' está nula.")
		return
		
	var vfx_instance = vfx_scene.instantiate()
	get_tree().current_scene.add_child(vfx_instance)
	
	vfx_instance.global_position = spawn_position
	vfx_instance.emitting = true
	vfx_instance.finished.connect(vfx_instance.queue_free.bind())
