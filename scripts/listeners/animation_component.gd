class_name AnimationComponent
extends Node

@export var flash_duration: float = 0.30

# --- CONFIGURAÇÃO SPINE ---
const SLOT_HAND_WEAPON = "Sword" 
const SLOT_SHEATH = "weapon_sheath"
const ATTACHMENT_SWORD = "Sword"

const ANIM_TRANSITION_SHEATH = "sheath_anim"

var spine_sprite: SpineSprite
var state_machine: Node 
var actor: Node

# Variáveis para controle de estado
var _current_sheathed_state: bool = false

func setup(p_state_machine: StateMachine, p_spine_sprite: SpineSprite, p_simple_state_machine: BaseSimpleStateMachine = null):
	if p_state_machine:
		state_machine = p_state_machine
	elif p_simple_state_machine:
		state_machine = p_simple_state_machine
	
	spine_sprite = p_spine_sprite
	actor = get_parent()
	
	assert(state_machine != null, "AnimationComponent: StateMachine não encontrada.")
	assert(spine_sprite != null, "AnimationComponent: SpineSprite não encontrado.")
	assert(actor != null, "AnimationComponent: Actor não encontrado.")
	
	if spine_sprite.normal_material:
		spine_sprite.normal_material = spine_sprite.normal_material.duplicate()	
	
	if state_machine.has_signal("phase_changed"):
		state_machine.phase_changed.connect(_on_phase_changed)

	ImpactResolver.impact_resolved.connect(_on_impact_resolved)
	
	if actor.has_signal("posture_action_triggered"):
		actor.posture_action_triggered.connect(_on_posture_action_triggered)
		
	call_deferred("_initialize_sword_state")

func _initialize_sword_state():
	if is_instance_valid(actor):
		var val = actor.get("is_sheathed")
		if val != null:
			_current_sheathed_state = val
		else:
			_current_sheathed_state = false
			
	_enforce_sword_attachment_state(true)

func _process(_delta):
	if is_instance_valid(actor) and is_instance_valid(spine_sprite):
		_enforce_sword_attachment_state()

func play_shader_flash():
	if not is_instance_valid(spine_sprite) or not spine_sprite.normal_material:
		return
	var material = spine_sprite.normal_material as ShaderMaterial
	if not material: return
	var tween = create_tween()
	material.set_shader_parameter("flash_modifier", 1.0)
	tween.tween_property(material, "shader_parameter/flash_modifier", 0.0, flash_duration).set_ease(Tween.EASE_IN)

func _on_impact_resolved(result: ContactResult):
	if result.defender_node != actor: return
	if result.defender_outcome == ContactResult.DefenderOutcome.BLOCKED or \
	   result.defender_outcome == ContactResult.DefenderOutcome.HIT:
		play_shader_flash()

func _on_phase_changed(phase_data: Dictionary):
	if not is_instance_valid(spine_sprite): return

	if phase_data.has("animation_to_play"):
		var anim_name: StringName = phase_data["animation_to_play"]
		if anim_name == &"": return

		var animation_state = spine_sprite.get_animation_state()
		if not animation_state: return

		animation_state.set_animation(anim_name, _should_animation_loop(anim_name), 0)

func _on_posture_action_triggered(action_name: String):
	if not is_instance_valid(spine_sprite): return
	var animation_state = spine_sprite.get_animation_state()
	if not animation_state: return
	
	if action_name == ANIM_TRANSITION_SHEATH:
		var entry = animation_state.set_animation(ANIM_TRANSITION_SHEATH, false, 1)
		
		if entry:
			entry.set_mix_duration(0.1)
		
		var duration = 0.5
		if entry and entry.get_animation():
			duration = entry.get_animation().get_duration()
		
		var timer = get_tree().create_timer(duration)
		timer.timeout.connect(_clear_action_track)
		
	elif action_name == "unsheath_anim":
		_clear_action_track()
		
		var current_track_0 = animation_state.get_current(0)
		if current_track_0:
			var current_anim_name = current_track_0.get_animation().get_name()
			animation_state.set_animation(current_anim_name, _should_animation_loop(current_anim_name), 0)

func _clear_action_track():
	if not is_instance_valid(spine_sprite): return
	var animation_state = spine_sprite.get_animation_state()
	if animation_state:
		animation_state.set_empty_animation(1, 0.0)

func _enforce_sword_attachment_state(force: bool = false):
	var skeleton = spine_sprite.get_skeleton()
	if not skeleton: return
	
	var is_sheathed = false
	var val = actor.get("is_sheathed")
	if val != null:
		is_sheathed = val
	
	if is_sheathed:
		skeleton.set_attachment(SLOT_HAND_WEAPON, "") 
		skeleton.set_attachment(SLOT_SHEATH, ATTACHMENT_SWORD)
	else:
		skeleton.set_attachment(SLOT_SHEATH, "")
		skeleton.set_attachment(SLOT_HAND_WEAPON, ATTACHMENT_SWORD)

func _should_animation_loop(anim_name: StringName) -> bool:
	return anim_name in [&"idle", &"walk", &"run", &"run-fast", &"idle-relaxed", &"jump", &"fall"]
