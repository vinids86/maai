# This component handles the physics of movement for its parent body.
# It knows "how" to move, but doesn't know about player input.
# Attach this script to the "MovementComponent" node in the Player scene.
extends Node

# By using @export, we can see and edit these values directly in the Godot Inspector.
# This makes tweaking the game feel much faster.
@export var speed = 300.0
# Renamed for clarity, reflecting its purpose as a vertical dodge.
@export var vertical_dodge_velocity = -400.0

# This variable will hold a reference to the parent CharacterBody2D.
var character_body: CharacterBody2D

# Get the gravity value from the project settings to ensure consistency.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


# _ready is called when the node and its children have entered the scene tree.
# It's the perfect place to set up references between nodes.
func _ready():
	# get_parent() returns the node this component is attached to.
	# We store it in the character_body variable for easy access later.
	# This line assumes the parent will ALWAYS be a CharacterBody2D.
	character_body = get_parent()


# This function handles the continuous "walking" physics.
func process_physics(delta, walk_direction):
	# --- GRAVITY ---
	# If the player is not on the floor, apply gravity.
	if not character_body.is_on_floor():
		character_body.velocity.y += gravity * delta

	# --- HORIZONTAL MOVEMENT ---
	if walk_direction:
		character_body.velocity.x = walk_direction * speed
	else:
		# If no key is pressed, slow the player down to a stop.
		character_body.velocity.x = move_toward(character_body.velocity.x, 0, speed)

	# --- APPLY MOVEMENT ---
	# The component is responsible for calling the final move function.
	character_body.move_and_slide()


# This is our new, more flexible dodge function. It takes a direction vector.
func execute_dodge(direction: Vector2):
	# For now, we only allow dodging when on the floor.
	if not character_body.is_on_floor():
		return

	# Check if the primary intent is a vertical dodge (upwards).
	if direction.y < 0:
		character_body.velocity.y = vertical_dodge_velocity
	
	# This is a placeholder for a future horizontal dodge (dash).
	if direction.x != 0:
		# We can implement a dash here later.
		# For example: character_body.velocity.x = direction.x * 600
		print("Horizontal dodge intent detected. Direction: ", direction.x)
