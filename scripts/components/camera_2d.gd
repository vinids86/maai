class_name GameCamera2D
extends Camera2D

enum ShakePreset { LEVE, MEDIO, FORTE }

@export var preset: ShakePreset = ShakePreset.MEDIO : set = set_preset

@export var max_offset: float = 10.0
@export var frequency: float = 25.0
@export var decay_rate: float = 2.5
@export var resting_offset: Vector2 = Vector2(250, -400)

var trauma: float = 0.0
var _rng := RandomNumberGenerator.new()
var _shake_offset := Vector2.ZERO 
var _time_accum := 0.0

@export_group("Dynamic Zoom")
@export var exploration_zoom: Vector2 = Vector2(0.65, 0.65)
@export var combat_zoom: Vector2 = Vector2(1.0, 1.0)
@export var zoom_speed: float = 2.0
@export var combat_cooldown: float = 3.0

var _combat_timer: float = 0.0
var _is_in_combat_mode: bool = false : set = _set_combat_mode
var _enemies_in_combat: Array[Node] = []
var _force_exploration_timer: float = 0.0

@export_group("Manual Peek Control")
@export var max_peek_offset: float = 500.0 
@export var peek_delay: float = 0.4
@export var peek_smooth_speed: float = 3.0 
@export var input_deadzone: float = 0.3

var _peek_offset: Vector2 = Vector2.ZERO
var _peek_timer: float = 0.0

var _cinematic_layer: CanvasLayer
var _top_bar: ColorRect
var _bottom_bar: ColorRect
const BAR_HEIGHT: int = 200

func _ready():
	_rng.randomize()
	apply_preset()
	offset = resting_offset
	
	add_to_group("MainCamera")
	zoom = exploration_zoom
	
	_setup_cinematic_bars()

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
	_update_combat_state(delta)
	_update_zoom(delta)
	_process_manual_peek(delta)

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
		
	offset = resting_offset + _shake_offset + _peek_offset

func _process_manual_peek(delta: float) -> void:
	var input_vector = Input.get_vector("camera_look_left", "camera_look_right", "camera_look_up", "camera_look_down")
	
	if input_vector.length() < input_deadzone:
		_peek_timer = 0.0
		_peek_offset = _peek_offset.lerp(Vector2.ZERO, peek_smooth_speed * delta)
		return

	_peek_timer += delta
	
	if _peek_timer >= peek_delay:
		var target_peek = input_vector.normalized() * max_peek_offset
		_peek_offset = _peek_offset.lerp(target_peek, peek_smooth_speed * delta)

func _update_combat_state(delta: float) -> void:
	if _force_exploration_timer > 0:
		_force_exploration_timer -= delta

	for i in range(_enemies_in_combat.size() - 1, -1, -1):
		if not is_instance_valid(_enemies_in_combat[i]):
			_enemies_in_combat.remove_at(i)

	if _enemies_in_combat.size() > 0 and _force_exploration_timer <= 0:
		_is_in_combat_mode = true
		_combat_timer = combat_cooldown
	else:
		if _combat_timer > 0 and _force_exploration_timer <= 0:
			_combat_timer -= delta
		else:
			_is_in_combat_mode = false

func _update_zoom(delta: float) -> void:
	var target_zoom = exploration_zoom
	if _is_in_combat_mode:
		target_zoom = combat_zoom
		
	var current_zoom_speed = zoom_speed
	if _force_exploration_timer > 0:
		current_zoom_speed = zoom_speed * 2.5
		
	zoom = zoom.lerp(target_zoom, current_zoom_speed * delta)

func register_enemy_aggro(enemy: Node) -> void:
	if not _enemies_in_combat.has(enemy):
		_enemies_in_combat.append(enemy)
		if _force_exploration_timer <= 0:
			_is_in_combat_mode = true
			_combat_timer = combat_cooldown

func unregister_enemy_aggro(enemy: Node) -> void:
	if _enemies_in_combat.has(enemy):
		_enemies_in_combat.erase(enemy)

func force_combat_mode(duration: float = 5.0) -> void:
	_is_in_combat_mode = true
	_combat_timer = max(_combat_timer, duration)

func on_enemy_death_zoom_out(duration: float = 1.5) -> void:
	_force_exploration_timer = duration
	_combat_timer = 0
	
func _setup_cinematic_bars() -> void:
	# Cria o CanvasLayer (UI) via código
	_cinematic_layer = CanvasLayer.new()
	_cinematic_layer.layer = 90 # Fica abaixo do HUD principal, mas acima do jogo
	add_child(_cinematic_layer)
	
	# Cria a Barra Superior
	_top_bar = ColorRect.new()
	_top_bar.color = Color.BLACK
	_top_bar.size = Vector2(get_viewport_rect().size.x, BAR_HEIGHT)
	_top_bar.position.y = -BAR_HEIGHT # Escondida pra cima
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_cinematic_layer.add_child(_top_bar)
	
	# Cria a Barra Inferior
	_bottom_bar = ColorRect.new()
	_bottom_bar.color = Color.BLACK
	_bottom_bar.size = Vector2(get_viewport_rect().size.x, BAR_HEIGHT)
	_bottom_bar.position.y = get_viewport_rect().size.y # Escondida pra baixo
	_bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_cinematic_layer.add_child(_bottom_bar)

func _set_combat_mode(value: bool) -> void:
	# Evita rodar a lógica se o valor não mudou
	if _is_in_combat_mode == value:
		return
		
	_is_in_combat_mode = value
	
	# Se o jogo ainda não estiver pronto (no _init), não tenta animar
	if not is_inside_tree(): return

	# Animação das Barras
	var vp_size = get_viewport_rect().size
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if _is_in_combat_mode:
		# Entrou em combate: Barras aparecem
		tween.tween_property(_top_bar, "position:y", 0.0, 0.5)
		tween.tween_property(_bottom_bar, "position:y", vp_size.y - BAR_HEIGHT, 0.5)
	else:
		# Saiu de combate: Barras somem
		tween.tween_property(_top_bar, "position:y", -BAR_HEIGHT, 0.5)
		tween.tween_property(_bottom_bar, "position:y", vp_size.y, 0.5)
