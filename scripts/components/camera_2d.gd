class_name GameCamera2D
extends Camera2D

# --- SEU CÓDIGO ORIGINAL DE SHAKE ---
enum ShakePreset { LEVE, MEDIO, FORTE }

@export var preset: ShakePreset = ShakePreset.MEDIO : set = set_preset

@export var max_offset: float = 10.0
@export var frequency: float = 25.0
@export var decay_rate: float = 2.5
@export var resting_offset: Vector2 = Vector2(250, -400) # Seu offset original

var trauma: float = 0.0
var _rng := RandomNumberGenerator.new()
var _shake_offset := Vector2.ZERO 
var _time_accum := 0.0

# --- ADIÇÃO: ZOOM DINÂMICO ---
@export_group("Dynamic Zoom")
@export var exploration_zoom: Vector2 = Vector2(0.7, 0.7) # Zoom out fora de combate
@export var combat_zoom: Vector2 = Vector2(1.0, 1.0)      # Zoom normal em combate
@export var zoom_speed: float = 2.0
@export var combat_cooldown: float = 3.0

var _combat_timer: float = 0.0
var _is_in_combat_mode: bool = false
var _enemies_in_combat: Array[Node] = []

func _ready():
	_rng.randomize()
	apply_preset()
	offset = resting_offset
	
	add_to_group("MainCamera")
	
	# Começa com o zoom de exploração
	zoom = exploration_zoom

func set_preset(value):
	preset = value
	apply_preset()

func apply_preset():
	match preset:
		ShakePreset.LEVE:
			max_offset = 8.0
			decay_rate = 3.0
			frequency = 25.0
		ShakePreset.MEDIO:
			max_offset = 15.0
			decay_rate = 2.3
			frequency = 30.0
		ShakePreset.FORTE:
			max_offset = 25.0
			decay_rate = 1.8
			frequency = 35.0

func add_trauma(amount: float = 0.35) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:	
	# 1. Lógica de Shake (Original)
	if trauma > 0.0001:
		_time_accum += delta
		var interval = 1.0 / max(frequency, 1.0)

		if _time_accum >= interval:
			_time_accum = 0.0
			var dir := Vector2(
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0)
			).normalized()
			
			var target_shake_offset = dir * (trauma * max_offset)
			_shake_offset = _shake_offset.lerp(target_shake_offset, 0.45)

		trauma = max(trauma - decay_rate * delta, 0.0)
	else:
		_shake_offset = _shake_offset.lerp(Vector2.ZERO, 0.15)
		trauma = 0.0
		
	offset = resting_offset + _shake_offset
	
	# 2. Lógica de Zoom (Adicionada)
	_update_combat_state(delta)
	_update_zoom(delta)

func _update_combat_state(delta: float) -> void:
	# Limpa inimigos mortos/deletados
	for i in range(_enemies_in_combat.size() - 1, -1, -1):
		if not is_instance_valid(_enemies_in_combat[i]):
			_enemies_in_combat.remove_at(i)

	if _enemies_in_combat.size() > 0:
		_is_in_combat_mode = true
		_combat_timer = combat_cooldown
	else:
		if _combat_timer > 0:
			_combat_timer -= delta
		else:
			_is_in_combat_mode = false

func _update_zoom(delta: float) -> void:
	var target_zoom = exploration_zoom
	if _is_in_combat_mode:
		target_zoom = combat_zoom
		
	# Suaviza a transição do zoom
	zoom = zoom.lerp(target_zoom, zoom_speed * delta)

# --- MÉTODOS PÚBLICOS PARA O AI CONTROLLER ---

func register_enemy_aggro(enemy: Node) -> void:
	if not _enemies_in_combat.has(enemy):
		_enemies_in_combat.append(enemy)
		_is_in_combat_mode = true
		_combat_timer = combat_cooldown

func unregister_enemy_aggro(enemy: Node) -> void:
	if _enemies_in_combat.has(enemy):
		_enemies_in_combat.erase(enemy)

func force_combat_mode(duration: float = 5.0) -> void:
	_is_in_combat_mode = true
	_combat_timer = max(_combat_timer, duration)
