class_name AnimationComponent
extends Node

@export var flash_duration: float = 0.15

var spine_sprite: SpineSprite
var state_machine: StateMachine
var actor: Node

func setup(p_state_machine: StateMachine, p_spine_sprite: SpineSprite):
	state_machine = p_state_machine
	spine_sprite = p_spine_sprite
	actor = get_parent()
	
	assert(state_machine != null, "AnimationComponent: StateMachine recebida no setup é nula.")
	assert(spine_sprite != null, "AnimationComponent: SpineSprite recebido no setup é nulo.")
	assert(actor != null, "AnimationComponent: Não foi possível obter o nó pai (ator).")
	
	if spine_sprite.normal_material:
		spine_sprite.normal_material = spine_sprite.normal_material.duplicate()	
	state_machine.phase_changed.connect(_on_phase_changed)

	ImpactResolver.impact_resolved.connect(_on_impact_resolved)

func play_shader_flash():
	if not is_instance_valid(spine_sprite) or not spine_sprite.normal_material:
		return
		
	var material = spine_sprite.normal_material as ShaderMaterial
	if not material:
		return

	var tween = create_tween()
	
	material.set_shader_parameter("flash_modifier", 1.0)
	
	tween.tween_property(material, "shader_parameter/flash_modifier", 0.0, flash_duration).set_ease(Tween.EASE_IN)

func _on_impact_resolved(result: ContactResult):
	if result.defender_node != actor:
		return

	if result.defender_outcome == ContactResult.DefenderOutcome.BLOCKED:
		play_shader_flash()

func _on_phase_changed(phase_data: Dictionary):
	if not is_instance_valid(spine_sprite): return

	if phase_data.has("animation_to_play"):
		var anim_name: StringName = phase_data["animation_to_play"]

		if anim_name == &"":
			return

		var animation_state = spine_sprite.get_animation_state()
		if not animation_state: return

		var current_anim_name: String = ""
		var current_track_entry = animation_state.get_current(0)
		if current_track_entry and current_track_entry.get_animation():
			current_anim_name = current_track_entry.get_animation().get_name()
		
		animation_state.set_animation(anim_name, _should_animation_loop(anim_name), 0)

func _should_animation_loop(anim_name: StringName) -> bool:
	return anim_name in [&"idle", &"walk", &"run"]
