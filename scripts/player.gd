# This script handles player input and delegates actions to its components.
# It knows "what" the player wants to do, but not "how" to do it.
extends CharacterBody2D

# A reference to our MovementComponent node. The @onready keyword ensures
# the variable is assigned right before the scene starts, after the node is ready.
@onready var movement_component = $MovementComponent


# _physics_process is the correct place to handle input for physics actions.
func _physics_process(delta):
	# --- DODGE HANDLING ---
	# First, check if the main dodge action was just pressed.
	if Input.is_action_just_pressed("dodge"):
		# At the moment the dodge is pressed, get the directional input from the player.
		var dodge_direction = get_dodge_direction()
		
		# If there is a directional input, delegate the dodge action.
		# This prepares for a neutral dodge (no direction) in the future.
		if dodge_direction != Vector2.ZERO:
			movement_component.execute_dodge(dodge_direction)

	# --- MOVEMENT HANDLING ---
	# This runs every frame, independently of the dodge.
	# Get horizontal movement direction for walking.
	var walk_direction = Input.get_axis("move_left", "move_right")
	
	# Delegate movement physics to the component.
	movement_component.process_physics(delta, walk_direction)


# Gathers the directional input to determine the dodge's vector.
func get_dodge_direction() -> Vector2:
	# We use get_vector which is perfect for combining directional inputs
	# from both keyboard (WASD) and controller joystick.
	# Note: get_vector uses "ui_up" by default for the y-axis. We will create "move_up".
	# For now, let's build it manually for clarity.
	var horizontal_input = Input.get_axis("move_left", "move_right")
	var vertical_input = 0.0
	if Input.is_action_pressed("move_up"):
		vertical_input = -1.0 # In Godot 2D, -Y is up.
		
	# .normalized() ensures the vector has a length of 1, which is crucial for
	# consistent speed when moving diagonally in the future.
	return Vector2(horizontal_input, vertical_input).normalized()
