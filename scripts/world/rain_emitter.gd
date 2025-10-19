extends GPUParticles2D

@export var camera_to_follow: Camera2D

func _ready():
	if not camera_to_follow:
		printerr("Emissor de chuva não conseguiu encontrar a Camera2D para seguir.")

func _process(_delta):
	if camera_to_follow:
		global_position.x = camera_to_follow.global_position.x
