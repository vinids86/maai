class_name AnimationListener
extends Node

var spine_sprite: SpineSprite
var state_machine: StateMachine

func setup(p_state_machine: StateMachine, p_spine_sprite: SpineSprite):
	self.state_machine = p_state_machine
	self.spine_sprite = p_spine_sprite
	
	assert(state_machine != null, "AnimationListener: StateMachine recebida no setup é nula.")
	assert(spine_sprite != null, "AnimationListener: SpineSprite recebido no setup é nulo.")
	
	state_machine.phase_changed.connect(_on_phase_changed)


func _on_phase_changed(phase_data: Dictionary):
	if not is_instance_valid(spine_sprite): return

	if phase_data.has("animation_to_play"):
		var anim_name: StringName = phase_data["animation_to_play"]
		var spine_anim_name: String = _get_spineboy_animation_for(anim_name)

		var current_anim_name: String = ""
		var animation_state = spine_sprite.get_animation_state()
		if animation_state:
			var current_track_entry = animation_state.get_current(0)
			if current_track_entry and current_track_entry.get_animation():
				current_anim_name = current_track_entry.get_animation().get_name()
		
		if spine_anim_name and current_anim_name != spine_anim_name:
			var should_loop: bool = _should_animation_loop(spine_anim_name)
			
			animation_state.set_animation(spine_anim_name, should_loop, 0)


func _get_spineboy_animation_for(original_anim_name: StringName) -> String:
	match original_anim_name:
		&"Idle": return "idle"
		&"Walk", &"Run": return "run"
		&"Jump": return "jump"
		&"light_attack_1": return "shoot"
		&"Parry": return "portal"
		_: return "idle"


func _should_animation_loop(anim_name: String) -> bool:
	return anim_name in ["idle", "run"]
