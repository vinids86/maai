extends Area2D

enum SpawnType { FIXED_POINTS, RELATIVE_TO_PLAYER }

# --- CONFIGURAÇÃO ---
@export_group("Combat Config")
@export var enemy_list: Array[PackedScene] 
@export var spawn_delay: float = 1.5       
@export var loop_encounter: bool = false   

@export_group("Spawn Settings")
@export var spawn_mode: SpawnType = SpawnType.FIXED_POINTS

# OPÇÃO A: Lista de Pontos Fixos (Recomendado para evitar bugs de parede)
# O inimigo 1 usa o ponto 0, Inimigo 2 usa o ponto 1, etc.
@export var spawn_points: Array[Marker2D] 

# OPÇÃO B: Relativo ao Player (Mais dinâmico, mas cuidado com paredes)
# Distância em X onde o inimigo vai aparecer (ex: 300px a frente ou atrás)
@export var relative_distance: float = 200.0 

# Sinais
signal combat_started
signal wave_cleared(wave_index)
signal combat_finished

var _current_index: int = 0
var _active: bool = false
var _finished: bool = false
var _current_enemy: Node = null

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	if body is Player and not _active and not _finished:
		_start_combat(body)

func _start_combat(_player_ref: Player):
	_active = true
	print("Combate iniciado na zona: ", name)
	emit_signal("combat_started")
	set_deferred("monitoring", false)
	_spawn_next_enemy()

func _spawn_next_enemy():
	if _current_index >= enemy_list.size():
		if loop_encounter:
			_current_index = 0
		else:
			_finish_combat()
			return

	var enemy_scene = enemy_list[_current_index]
	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		var spawn_pos = global_position # Padrão: centro da area

		# --- LÓGICA DE POSICIONAMENTO ---
		if spawn_mode == SpawnType.FIXED_POINTS and not spawn_points.is_empty():
			# Pega o marker correspondente ao índice do inimigo.
			# O operador % (módulo) faz girar se tiver menos markers que inimigos.
			var marker = spawn_points[_current_index % spawn_points.size()]
			if marker:
				spawn_pos = marker.global_position
				
		elif spawn_mode == SpawnType.RELATIVE_TO_PLAYER:
			# Tenta achar o player para usar como referência
			var player = get_tree().get_first_node_in_group("player") # Certifique-se que o player está no grupo "player"
			if player:
				# Define o lado baseado na direção que o player está olhando ou aleatório
				# Aqui faremos: Aparecer na frente do player (baseado na escala/direção dele)
				var direction = 1
				if player.global_position.x > global_position.x: # Se player está à direita da zona, inverte
					direction = -1
				
				# Alterna lado a cada inimigo para não ficar chato
				if _current_index % 2 == 1:
					direction *= -1
					
				spawn_pos = player.global_position + Vector2(relative_distance * direction, 0)

		enemy.global_position = spawn_pos
		get_tree().current_scene.add_child(enemy)
		_current_enemy = enemy
		
		# Conexão de vida
		var health = enemy.find_child("HealthComponent")
		if health:
			health.died.connect(_on_enemy_died)

func _on_enemy_died():
	emit_signal("wave_cleared", _current_index)
	_current_index += 1
	await get_tree().create_timer(spawn_delay).timeout

	_spawn_next_enemy()

func _finish_combat():
	_finished = true
	_active = false
	print("Zona de combate concluída!")
	emit_signal("combat_finished")
