class_name SimplePatrolState
extends SimpleState

var _direction: float = 1.0
var _profile: LocomotionProfile

func enter(_args: Dictionary = {}):
	if owner_node.has_method("get_locomotion_profile"):
		_profile = owner_node.get_locomotion_profile()
	
	state_machine.emit_phase_change({
		"state": "SimplePatrolState",
		"phase": "walk",
		"animation_to_play": _profile.walk_animation
	})
	
	# Sincronia inicial baseada na escala do sprite, nao do root
	var sprite = owner_node.get_node_or_null("SpineSprite")
	if sprite and sprite.scale.x < 0:
		_direction = -1.0
	else:
		_direction = 1.0

func process_physics(delta: float) -> Vector2:
	if wall_detector and not wall_detector.has_floor_ahead(1):
		_direction *= -1.0
		_flip_owner()
	elif wall_detector and wall_detector.is_colliding(1):
		_direction *= -1.0
		_flip_owner()
	elif owner_node.is_on_wall():
		_direction *= -1.0
		_flip_owner()
	
	var speed = 0.0
	if _profile:
		speed = _profile.speed
	
	var velocity_x = _direction * speed
	
	var velocity_y = owner_node.velocity.y
	if not owner_node.is_on_floor():
		velocity_y += 980.0 * delta
	
	return Vector2(velocity_x, velocity_y)

func _flip_owner():
	if owner_node.has_method("set_facing_direction"):
		owner_node.set_facing_direction(_direction)
