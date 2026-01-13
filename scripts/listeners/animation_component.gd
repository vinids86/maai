class_name AnimationComponent
extends Node

@export var flash_duration: float = 0.30

var spine_sprite: SpineSprite
var state_machine: Node 
var actor: Node

func setup(p_state_machine: StateMachine, p_spine_sprite: SpineSprite, p_simple_state_machine: BaseSimpleStateMachine = null):
	if p_state_machine:
		state_machine = p_state_machine
	elif p_simple_state_machine:
		state_machine = p_simple_state_machine
	
	spine_sprite = p_spine_sprite
	actor = get_parent()
	
	assert(state_machine != null, "AnimationComponent: Nenhuma StateMachine (padrão ou simples) fornecida no setup.")
	assert(spine_sprite != null, "AnimationComponent: SpineSprite recebido no setup é nulo.")
	assert(actor != null, "AnimationComponent: Não foi possível obter o nó pai (ator).")
	
	if spine_sprite.normal_material:
		spine_sprite.normal_material = spine_sprite.normal_material.duplicate()	
	
	# Ambas as máquinas de estado emitem esse sinal
	if state_machine.has_signal("phase_changed"):
		state_machine.phase_changed.connect(_on_phase_changed)

	ImpactResolver.impact_resolved.connect(_on_impact_resolved)
	
	# Conecta ao sinal de postura do Player se o ator for um Player
	if actor.has_signal("posture_action_triggered"):
		actor.posture_action_triggered.connect(_on_posture_action_triggered)

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

	if result.defender_outcome == ContactResult.DefenderOutcome.BLOCKED or \
	   result.defender_outcome == ContactResult.DefenderOutcome.HIT:
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
		# Track 0 é a base (locomoção, estados principais)
		var current_track_entry = animation_state.get_current(0)
		if current_track_entry and current_track_entry.get_animation():
			current_anim_name = current_track_entry.get_animation().get_name()
		
		# Define a animação na Track 0
		animation_state.set_animation(anim_name, _should_animation_loop(anim_name), 0)

# --- NOVO CALLBACK PARA ANIMAÇÕES DE TRANSIÇÃO (Action Track) ---
func _on_posture_action_triggered(action_name: String):
	if not is_instance_valid(spine_sprite): return
	
	var animation_state = spine_sprite.get_animation_state()
	if not animation_state: return
	
	# Define a animação na Track 1 (Action Track)
	# Track 1 roda por cima da Track 0, permitindo que as pernas continuem correndo/andando
	# enquanto o tronco executa a ação de embainhar/desembainhar.
	
	# Toca a animação uma vez (loop = false)
	animation_state.set_animation(action_name, false, 1)
	
	# Importante: Adiciona uma animação "vazia" logo após para limpar a track suavemente.
	# O mix_duration (0.2s aqui) garante que o braço volte suavemente para a posição da animação base (Track 0).
	animation_state.add_empty_animation(1, 0.2, 0.0)

func _should_animation_loop(anim_name: StringName) -> bool:
	# Adicione aqui outras animações de locomoção se necessário (ex: idle_exploration, run_exploration)
	return anim_name in [&"idle", &"walk", &"run", &"run-fast", &"idle-relaxed"]
