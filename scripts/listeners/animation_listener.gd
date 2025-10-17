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

		if anim_name == &"":
			return

		var animation_state = spine_sprite.get_animation_state()
		if not animation_state: return

		var current_anim_name: String = ""
		var current_track_entry = animation_state.get_current(0)
		if current_track_entry and current_track_entry.get_animation():
			current_anim_name = current_track_entry.get_animation().get_name()
		
		if current_anim_name != anim_name:
			var should_loop: bool = _should_animation_loop(anim_name)
			animation_state.set_animation(anim_name, should_loop, 0)

func _should_animation_loop(anim_name: StringName) -> bool:
	return anim_name in [&"idle", &"walk", &"run"]
