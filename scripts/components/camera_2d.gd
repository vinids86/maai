extends Camera2D

# === PRESETS ===
enum ShakePreset { LEVE, MEDIO, FORTE }

@export var preset: ShakePreset = ShakePreset.MEDIO : set = set_preset

# === CONFIGURAÇÕES ===
@export var max_offset: float = 10.0
@export var frequency: float = 25.0
@export var decay_rate: float = 2.5

var trauma: float = 0.0
var _rng := RandomNumberGenerator.new()
var _target_offset := Vector2.ZERO
var _time_accum := 0.0

func _ready():
	_rng.randomize()
	apply_preset()

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
	if trauma <= 0.0001:
		offset = offset.lerp(Vector2.ZERO, 0.15)
		trauma = 0.0
		return

	_time_accum += delta
	var interval = 1.0 / max(frequency, 1.0)

	if _time_accum >= interval:
		_time_accum = 0.0
		var dir := Vector2(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0)
		).normalized()
		_target_offset = dir * (trauma * max_offset)

	offset = offset.lerp(_target_offset, 0.45)
	trauma = max(trauma - decay_rate * delta, 0.0)
