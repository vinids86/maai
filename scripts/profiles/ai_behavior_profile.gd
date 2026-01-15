class_name AIBehaviorProfile
extends Resource

# Agora usamos Arrays do nosso novo tipo AIActionStep
@export var phase_1: Array[AIActionStep]
@export var phase_2: Array[AIActionStep]

# --- CONVERSOR DE COMPATIBILIDADE ---
# Esta função converte os Resources de volta para Dicionários.
# Isso permite que a gente NÃO precise reescrever o AIController inteiro agora.
func get_sequence(phase_name: String) -> Array[Dictionary]:
	var source_array: Array[AIActionStep]
	
	if phase_name == "phase_1":
		source_array = phase_1
	else:
		source_array = phase_2
	
	var result: Array[Dictionary] = []
	for step in source_array:
		if step:
			result.append({
				"defense": step.defense,
				"riposte": step.riposte
			})
	return result
