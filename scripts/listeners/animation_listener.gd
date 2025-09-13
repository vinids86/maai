class_name AnimationListener
extends Node

# --- REFERÊNCIAS ---
# Vamos associar o AnimationPlayer através do editor.
@export var animation_player: AnimationPlayer
@export var state_machine: StateMachine

# --- CICLO DE VIDA DO GODOT ---

func _ready():
	# Verificações para garantir que tudo está configurado corretamente.
	assert(animation_player != null, "AnimationListener: AnimationPlayer não foi atribuído no Inspetor.")
	assert(state_machine != null, "AnimationListener: StateMachine não foi atribuída no Inspetor.")
	
	# O Listener conecta-se ao sinal único da StateMachine.
	state_machine.phase_changed.connect(_on_phase_changed)

# --- HANDLER DO SINAL ---

func _on_phase_changed(phase_data: Dictionary):
	# O Listener é um executor "burro". Ele apenas verifica se a "encomenda"
	# tem uma instrução de animação para ele.
	if phase_data.has("animation_to_play"):
		var anim_name = phase_data["animation_to_play"]
		
		# Tocamos a animação apenas se ela for válida e não for a que já está a tocar.
		if anim_name and animation_player.current_animation != anim_name:
			animation_player.play(anim_name)
