extends CharacterBody2D

#####################################
# DUCK HUNT REMASTERED              #
# A fan game by Daniel the Fox      #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


####
# Inspired by the great tutorial "Duck Hunt in Godot 4" by 16BitDev.
# See https://www.youtube.com/watch?v=gLzwaMF8Zbk
# and https://github.com/16BitDev/duck-hunt/
#
# I made quite some changes and additions though! ;)
# See https://github.com/Daniel-The-Fox/duck-hunt-remastered/blob/main/README.md
####


# Definde signals emitted by this script
signal next_duck


# Initialize nodes used in script
@onready var animation_player = $AnimationPlayer
@onready var cursor_manager = $CursorManager
@onready var duck_drop_fall_player = $DuckDropFallPlayer
@onready var duck_drop_hit_player = $DuckDropHitPlayer
@onready var duck_quack_player = $DuckQuackPlayer
@onready var duck_scream_player = $DuckScreamPlayer
@onready var duck_sprite = $AnimatedSprite2D
@onready var quack_timer: Timer = $QuackTimer
@onready var wings_flap_player = $WingsFlapPlayer


# General settings and status variables
var current_duck_type: String
var duck_death_animation_suffix = "_death"
var duck_fall_animation_suffix = "_fall"
var duck_fall_multiplier = 150
var duck_fly_animation_suffix = "_fly"
var duck_hit = false
var duck_hit_position = Vector2(0, 0)
var duck_initial_quack = true
var duck_random_quack = true
var duck_random_quack_min_sec = 2
var duck_random_quack_max_sec = 5
var duck_types = [
	"brown",
	"blue",
	"red",
]
var speed: float = 100


# Function "_ready" is always called when node finished initial loading
# See https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-method-ready
func _ready():
	await _choose_random_duck_type(current_duck_type)
	_update_current_duck_type()
	wings_flap_player.play()
	if duck_random_quack:
		_random_duck_quack()
	# This is now handled in the main scene's GDScript to be able
	# to set a random starting x position for the duck.
	# Keeping this here as a reminder, though.
	#input_pickable = true
	#velocity = random_up_direction() * speed


# Function "_physics_process" is called during the physics processing step of the main loop
# Note: This method is only called if the node is present in the scene tree and has a velocity > 0!
# See https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-method-physics-process
# and https://kidscancode.org/godot_recipes/4.x/basics/understanding_delta/index.html
func _physics_process(delta):
	# move_and_collide() = Moves the body along the vector motion. Use delta to be frame independent.
	# If the engine detects a collision anywhere along this vector, the body will immediately stop moving.
	# See https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html
	var _collision = move_and_collide(velocity * delta)
	if _collision:
		# velocity.bounce() returns a new vector after colliding
		# See https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html#character-collision-response
		# and https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html#class-characterbody2d-property-velocity
		# and https://docs.godotengine.org/en/stable/classes/class_vector2.html#class-vector2-method-bounce
		velocity = velocity.bounce(_collision.get_normal())
		#print(current_duck_type + " duck collided with ", _collision.get_collider().name)
	duck_sprite.flip_h = velocity.x < 0
	if duck_random_quack:
		_random_duck_quack()


# We connected the node "Duck" to the signal "input_event" which causes
# the function "_on_input_event" to be called everytime an input event happens on the duck.
# We're only interested in the case when the duck got hit though.
# Requires input_pickable = true!
#
# See https://docs.godotengine.org/en/stable/classes/class_collisionobject2d.html#signals
# and https://docs.godotengine.org/en/stable/classes/class_collisionobject2d.html#class-collisionobject2d-property-input-pickable
# and https://docs.godotengine.org/en/stable/classes/class_inputevent.html#class-inputevent-method-is-action-pressed
func _on_input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed("left_click") and input_pickable:
		duck_hit = true
		input_pickable = false
		wings_flap_player.stop()
		quack_timer.stop()
		duck_quack_player.stop()
		duck_hit_position = Vector2(roundi(self.position.x), roundi(self.position.y))
		print("duck_hit_position: " + str(duck_hit_position))
		duck_scream_player.play()
		velocity = Vector2.ZERO
		animation_player.play(current_duck_type + duck_death_animation_suffix)
		await get_tree().create_timer(0.6).timeout
		duck_drop_fall_player.play()
		velocity = Vector2.DOWN * duck_fall_multiplier
		duck_sprite.play(current_duck_type + duck_fall_animation_suffix)
		await get_tree().create_timer(0.5).timeout
		# TODO: Find right spot and timing for ground hit sfx after fall...
		#duck_drop_hit_player.play()
		#await get_tree().create_timer(0.5).timeout


# Signal "screen_exited" on duck calls this function
# when the current duck instance left the screen
func _on_screen_exited():
	print(current_duck_type + " duck exited screen")
	next_duck.emit()
	# queue_free() = Queues a node for deletion at the end of the current frame.
	queue_free()


# Calculate a random velocity vector of length 1 ("nomalized")
# Attention: Assumes that "randomize()" is called in _ready of main scene!
# See https://docs.godotengine.org/en/stable/tutorials/math/vector_math.html#vector-math
# and https://docs.godotengine.org/en/stable/tutorials/math/random_number_generation.html
func random_up_direction() -> Vector2:
	var _randf_deg = randf_range(0, 180)
	# Using trigonometric functions to calculate x and y coords from random angle.
	# For details, see https://en.wikipedia.org/wiki/Unit_circle
	# and https://en.wikipedia.org/wiki/Unit_circle#/media/File:Unit_circle_angles_color.svg
	# and https://en.wikipedia.org/wiki/Exact_trigonometric_values
	#
	# Enforcing negative y value to force duck to fly upwards from the beginning,
	# as duck will always start (spawn) at random x position inside grass in main scene.
	#
	# Transforming random angle in degree tro radians,
	# as Godot's cos() and sin() functions only accept radians
	# For details, see https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#class-globalscope-method-cos
	var _random_direction = Vector2(
			cos(deg_to_rad(_randf_deg)),
			sin(-1 * deg_to_rad(_randf_deg)),
	)
	#print("_randf_deg: " + str(_randf_deg))
	#print("_random_direction: " + str(_random_direction))
	#print("_random_direction.normalized(): " + str(_random_direction.normalized()))
	return _random_direction.normalized()


# Attention: Assumes that "randomize()" is called in _ready of main scene!
# See https://docs.godotengine.org/en/stable/tutorials/math/random_number_generation.html
func _choose_random_duck_type(_random_duck=""):
	#print("current_animation duck: " + duck_sprite.get_animation())
	if _random_duck.is_empty():
		_random_duck = duck_types[randi_range(0, duck_types.size()-1)]
	print("random duck: " + _random_duck)
	if duck_initial_quack:
		duck_quack_player.play()
	duck_sprite.play(_random_duck + duck_fly_animation_suffix)


func _update_current_duck_type():
	current_duck_type = duck_sprite.get_animation().split("_")[0]
	if current_duck_type not in duck_types:
		current_duck_type = duck_types[0]
	#print("current_duck_type: " + current_duck_type)


func _random_duck_quack():
	if quack_timer.is_stopped():
		var _current_wait = quack_timer.wait_time
		while quack_timer.wait_time == _current_wait:
			quack_timer.wait_time = randi_range(
					duck_random_quack_min_sec,
					duck_random_quack_max_sec,
			)
		quack_timer.one_shot = true
		quack_timer.start()
		#print("quack_timer started")
		#print("Waiting " + str (quack_timer.wait_time) + " seconds before next quack")


# Signal "mouse_entered" on duck calls this function
func _on_mouse_entered() -> void:
	# Set red crosshairs cursor to indicate that duck is shootable now
	if input_pickable:
		cursor_manager.set_crosshairs_cursor()


# Signal "mouse_exited" on duck calls this function
func _on_mouse_exited() -> void:
	# Reset to default cursor to indicate that duck is NOT shootable anymore for now
	cursor_manager.set_default_cursor()


func _on_quack_timer_timeout() -> void:
	duck_quack_player.play()
