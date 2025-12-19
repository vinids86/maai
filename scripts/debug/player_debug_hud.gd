extends CanvasLayer

@export var actor_to_watch: NodePath
@onready var label: Label = $Label

var actor_name: String = "ACTOR" 

func _ready():
	var actor_node = get_node_or_null(actor_to_watch)
	if not is_instance_valid(actor_node):
		label.text = "HUD ERRO: Ator nao encontrado."
		return
		
	actor_name = actor_node.name.to_upper()
		
	var state_machine = actor_node.get_node("StateMachine")
	if not is_instance_valid(state_machine):
		label.text = "HUD ERRO: StateMachine nao encontrada."
		return

	state_machine.phase_changed.connect(_on_phase_changed)

func _on_phase_changed(data: Dictionary):
	var state_name = data.get("state_name", "ESTADO_DESCONHECIDO").to_upper()
	var phase_name = data.get("phase_name", "FASE_DESCONHECIDA").to_upper()
	
	var output_text = "%s: %s: %s" % [actor_name, state_name, phase_name]
	
	label.text = output_text
	#print(output_text)
