class_name Enemy
extends CharacterBody2D

@onready var state_machine: StateMachine = $StateMachine
@onready var ai_controller: AIController = $AIController

@export var visual_node: CanvasItem

var material_ref: ShaderMaterial
var facing_sign: int = 1
var facing_locked: bool = false

func _ready():
	assert(visual_node != null, "Enemy: O nó visual (visual_node) não foi atribuído no Inspetor.")
	
	if visual_node.material is ShaderMaterial:
		material_ref = visual_node.material

func _physics_process(delta: float):
	var walk_direction = ai_controller.get_walk_direction()
	var is_running = ai_controller.is_running()
	
	state_machine.process_physics(delta, walk_direction, is_running)
	move_and_slide()

func flash_red():
	if not material_ref:
		push_warning("Enemy: Nenhum ShaderMaterial encontrado no nó visual para o efeito de flash.")
		return
		
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
	
	tween.tween_property(material_ref, "shader_parameter/flash_modifier", 1.0, 0.0).from(1.0).set_delay(0.05)
	tween.tween_property(material_ref, "shader_parameter/flash_modifier", 0.0, 0.15)
