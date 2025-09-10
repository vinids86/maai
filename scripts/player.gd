# This script handles player input and delegates actions to its components.
# It knows "what" the player wants to do, but not "how" to do it.
extends CharacterBody2D

# A reference to our MovementComponent node. The @onready keyword ensures
# the variable is assigned right before the scene starts, after the node is ready.
@onready var movement_component = $MovementComponent


# _physics_process is still the right place to handle input for physics actions.
func _physics_process(delta):
	# 1. Get Input
	# We now use the custom actions "move_left" and "move_right" we created
	# in the Input Map. This works for both keyboard (A/D) and controller.
	var direction = Input.get_axis("move_left", "move_right")
	
	# 2. Delegate to Component
	# We call a function on the component, passing the necessary information.
	# The player script itself no longer knows anything about speed, gravity,
	# or even move_and_slide().
	movement_component.process_physics(delta, direction)
