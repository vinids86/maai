# This component handles the physics of movement for its parent body.
# It knows "how" to move, but doesn't know about player input.
# Attach this script to the "MovementComponent" node in the Player scene.
extends Node

# By using @export, we can see and edit these values directly in the Godot Inspector.
# This makes tweaking the game feel much faster.
@export var speed = 300.0
@export var jump_velocity = -400.0

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


# We create our own physics function that will be called by the player script.
func process_physics(delta, direction):
	# --- GRAVITY ---
	if not character_body.is_on_floor():
		character_body.velocity.y += gravity * delta

	# --- HORIZONTAL MOVEMENT ---
	if direction:
		character_body.velocity.x = direction * speed
	else:
		character_body.velocity.x = move_toward(character_body.velocity.x, 0, speed)

	# --- APPLY MOVEMENT ---
	# The component is responsible for calling the final move function.
	character_body.move_and_slide()
