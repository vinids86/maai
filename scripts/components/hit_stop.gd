extends Node

var _active := false
var _end_time := 0.0
var _token := 0
var _slow_scale := 0.01

func apply(duration: float, slow_scale: float = 0.01) -> void:
	if duration <= 0.0:
		return

	var now := Time.get_unix_time_from_system()
	_end_time = max(_end_time, now + duration)
	_slow_scale = slow_scale

	if _active:
		return

	_active = true
	_token += 1
	var my_token := _token
	var original_scale := Engine.time_scale
	Engine.time_scale = _slow_scale

	# Loop curto usando timer que IGNORA time_scale
	# (terceiro parâmetro = ignore_time_scale = true)
	while Time.get_unix_time_from_system() < _end_time and my_token == _token:
		await get_tree().create_timer(0.01, false, true).timeout

	# Se ninguém “esticou” no meio, encerra
	if my_token == _token:
		Engine.time_scale = 1.0
		_active = false
		_end_time = 0.0
