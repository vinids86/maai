class_name Enemy
extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var material_ref: ShaderMaterial

func _ready():
	var visual_node = find_child("ColorRect") # Altere para o nome do seu nó visual se for diferente
	if visual_node and visual_node.material is ShaderMaterial:
		material_ref = visual_node.material

func _physics_process(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	move_and_slide()

func flash_red():
	if not material_ref:
		push_warning("Enemy: Nenhum ShaderMaterial encontrado para o efeito de flash.")
		return
		
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
	
	# Animamos o parâmetro "flash_modifier" do shader de 1.0 (totalmente visível) para 0.0 (invisível)
	tween.tween_property(material_ref, "shader_parameter/flash_modifier", 1.0, 0.0).from(1.0).set_delay(0.05)
	tween.tween_property(material_ref, "shader_parameter/flash_modifier", 0.0, 0.15)
