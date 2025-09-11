# This component handles the physics of movement for its parent body.
# It knows "how" to move, but doesn't know about player input.
# Attach this script to the "MovementComponent" node in the Player scene.
extends Node

# By using @export, we can see and edit these values directly in the Godot Inspector.
# This makes tweaking the game feel much faster.
@export var speed = 300.0
@export var run_speed = 500.0 # New variable for running speed.
@export var vertical_dodge_velocity = -400.0

# This variable will hold a reference to the parent CharacterBody2D.
var character_body: CharacterBody2D

# Get the gravity value from the project settings to ensure consistency.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


# _ready is called when the node and its children have entered the scene tree.
func _ready():
	character_body = get_parent()


# This function now accepts an "is_running" flag to determine which speed to use.
func process_physics(delta, walk_direction, is_running):
	# --- GRAVITY ---
	if not character_body.is_on_floor():
		character_body.velocity.y += gravity * delta

	# --- HORIZONTAL MOVEMENT ---
	# Determine which speed to use based on the player's intent.
	var target_speed = speed
	if is_running:
		target_speed = run_speed
		
	# Apply movement based on the chosen speed.
	if walk_direction:
		character_body.velocity.x = walk_direction * target_speed
	else:
		# If no key is pressed, slow the player down to a stop.
		character_body.velocity.x = move_toward(character_body.velocity.x, 0, speed)

	# --- APPLY MOVEMENT ---
	character_body.move_and_slide()


# This is our new, more flexible dodge function. It takes a direction vector.
func execute_dodge(direction: Vector2):
	if not character_body.is_on_floor():
		return

	if direction.y < 0:
		character_body.velocity.y = vertical_dodge_velocity
	
	if direction.x != 0:
		print("Horizontal dodge intent detected. Direction: ", direction.x)
