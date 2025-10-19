class_name AudioComponent
extends Node

@export var state_machine: StateMachine
@export var footstep_sfx: AudioStream

func _ready():
	assert(state_machine != null, "AudioComponent: StateMachine não foi atribuída no Inspetor.")
	state_machine.phase_changed.connect(_on_phase_changed)

func _on_phase_changed(phase_data: Dictionary):
	if phase_data.has("sfx_to_play"):
		var sfx = phase_data["sfx_to_play"]
		if sfx is AudioStream:
			_play_sound_instance(sfx)

func play_footstep():
	if footstep_sfx:
		_play_sound_instance(footstep_sfx)
	else:
		print("AudioComponent: footstep_sfx não foi definido. Não é possível tocar o som do passo.")


func _play_sound_instance(sound_stream: AudioStream):
	if not sound_stream: return
	
	var player = AudioStreamPlayer.new()
	player.stream = sound_stream
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
