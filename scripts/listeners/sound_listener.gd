class_name SoundListener
extends Node

# --- REFERÊNCIAS ---
# Vamos associar o AudioStreamPlayer2D através do editor.
@export var audio_player: AudioStreamPlayer2D
@export var state_machine: StateMachine

# --- CICLO DE VIDA DO GODOT ---

func _ready():
	# Verificações para garantir que tudo está configurado corretamente.
	assert(audio_player != null, "SoundListener: AudioStreamPlayer2D não foi atribuído no Inspetor.")
	assert(state_machine != null, "SoundListener: StateMachine não foi atribuída no Inspetor.")
	
	# O Listener conecta-se ao sinal único da StateMachine.
	state_machine.phase_changed.connect(_on_phase_changed)

# --- HANDLER DO SINAL ---

func _on_phase_changed(phase_data: Dictionary):
	# O Listener verifica se a "encomenda" tem uma instrução de som para ele.
	if phase_data.has("sfx_to_play"):
		var sfx = phase_data["sfx_to_play"]
		
		# Tocamos o som apenas se ele for um recurso válido.
		if sfx is AudioStream:
			audio_player.stream = sfx
			audio_player.play()
