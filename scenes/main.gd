extends Node2D

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
# I made a lot of changes and additions though! ;)
# See https://github.com/Daniel-The-Fox/duck-hunt-remastered/blob/main/README.md
####


# Signals emitted by this script
signal highscore_screen_continued
signal intro_screen_continued


# Initialize nodes used in script
@onready var bell_player = $AudioPlayers/BellPlayer
@onready var bg_atmosphere_player = $AudioPlayers/BgAtmospherePlayer
@onready var bg_music_player = $AudioPlayers/BgMusicPLayer
@onready var bullets_debug_label = $InfoElements/BulletsDebugLabel
@onready var bullets_info = $InfoElements/BulletsInfo
@onready var bullets_sprite = $InfoElements/BulletsInfo/Bullets
@onready var foreground = $Foreground
@onready var dog_node = $Dog
@onready var duck_points_label = $InfoElements/DuckPointsLabel
@onready var duck_quack_player = $AudioPlayers/DuckQuackPlayer
@onready var ducks_shot_sprite = $InfoElements/HitsInfo/DucksShot
@onready var ducks_unshot_sprite = $InfoElements/HitsInfo/DucksUnshot
@onready var game_over_player = $AudioPlayers/GameOverPlayer
@onready var game_over_sign = $InfoElements/GameOverSign
@onready var game_over_timer = $GameOverTimer
@onready var ground_dog_walk = $GroundDogWalk
@onready var hits_info = $InfoElements/HitsInfo
@onready var info_elements = $InfoElements
@onready var intro_screen = $IntroScreen
@onready var intro_screen_timer = $IntroScreenTimer
@onready var round_complete_sign = $InfoElements/RoundCompleteSign
@onready var round_info = $InfoElements/RoundInfo
@onready var round_start_sign = $InfoElements/RoundStartSign
@onready var round_label = $InfoElements/RoundInfo/RoundLabel
@onready var score_info = $InfoElements/ScoreInfo
@onready var score_label = $InfoElements/ScoreInfo/ScoreLabel
@onready var shotgun_empty_player = $AudioPlayers/ShotgunEmptyPlayer
@onready var shotgun_reload_player = $AudioPlayers/ShotgunReloadPlayer
@onready var shotgun_shot_player = $AudioPlayers/ShotgunShotPlayer
@onready var success_player = $AudioPlayers/SuccessPlayer
@onready var time_elapsed_label = $InfoElements/TimeElapsedLabel
@onready var top_edge_grass = $TopEdgeGrass
@onready var version_label = $VersionLabel


# Init duck node
@export var duck_node: PackedScene
@export var highscore_node: PackedScene
var duck
var highscore_screen


# General settings
# TODO: Expose (export) to Godot GUI?
# TODO: Expose to Player in a game settings menu?
var bonus_pts_per_round_multiplier = 1000
var bullets_debug_label_show = false
var bullets_width = 8
var debug_round_mode = false
var dog_start_position = Vector2(29, 164)
var duck_pts_round_multiplier = 0.75
var duck_speed_round_multiplier = 5
var ducks_shot_width = 8
var ducks_shot_sprite_default_width = 1
var ducks_to_shoot_per_round = 10
var game_over_timeout_sec_min = 4
var intro_min_delay_sec = 7
var max_bullets = 3
var max_score = 9999999
var play_dog_intro = true
var play_round_complete_animation = true
var points_per_duck = 500
var present_hit_duck = true
var round_compl_anim_blink_cnt = 4
var round_compl_anim_blink_delay = 0.25
var round_complete_msg_delay_after = 0.5
var round_complete_msg_prefix = "GREAT!\n"
var round_label_prefix = "R "
var round_start_msg_delay = 1.0
var round_start_msg_prefix = "Round\n"
var score_seperator = ","
var show_duck_points = true
var show_duck_points_delay = 0.35
var show_intro_screen = true


# Shuffle bag for duck types to increase "randomness feel"
# by preventing the same duck type of getting picked directly after each other
# See https://docs.godotengine.org/en/stable/tutorials/math/random_number_generation.html#better-randomness-using-shuffle-bags
var duck_types_shuffle_bag = []


# Status variables
var browser_game = OS.has_feature("web")
var ignore_shots = false
var ducks_shot = 0

var bullets_current = max_bullets:
	# setter runs when the variable value is changed
	set(value):
		# prevent bullets from becoming negative
		if value >= 0:
			bullets_current = value
			bullets_debug_label.text = str(value)

var round_current = 1:
	set(value):
		round_current = value
		round_label.text = round_label_prefix + str(value)

var score_current = 0:
	set(value):
		if value > max_score:
			value = max_score
		score_current = value
		score_label.text = format_score(str(value))

var time_elapsed = 0
var time_elapsed_min = 0
var time_elapsed_sec = 0
var time_elapsed_string = str("00:00")
var time_now = 0
var time_start = 0


### Use for debugging/testing only!
var quick_debug_mode = false


# Called when the node enters the scene tree for the first time.
# Can be considered as main() as we know it from Python, C, etc. ;)
func _ready():
	### For testing/debugging
	#AudioServer.set_bus_mute(0, true)
	###
	ignore_shots = true
	# randomize() should be called in _ready() in main scene
	# See https://docs.godotengine.org/en/stable/tutorials/math/random_number_generation.html
	randomize()
	_init_labels()
	bg_music_player.play()
	### Quick debug mode
	if quick_debug_mode:
		print("\nATTENTION: Quick debug mode enabled!\n")
		bullets_debug_label_show = true
		debug_round_mode = true
		play_dog_intro = false
		play_round_complete_animation = false
		present_hit_duck = false
		show_intro_screen = false
	###
	if show_intro_screen:
		await _show_intro_screen()
	print("\nStarting new game...")
	print("Round " + str(round_current))
	time_start = Time.get_unix_time_from_system()
	print("time_start (unix seconds): " + str(time_start))
	print(
			"Started game at " +
			str(Time.get_datetime_string_from_unix_time(time_start))
	)
	_reset_ducks_shot()
	_reload_shotgun()
	bg_atmosphere_player.play()
	#print("dog_node.position: " + str(dog_node.position))
	if play_dog_intro:
		await _dog_jump_into_grass()
	await _show_round_start_sign()
	await get_tree().create_timer(1).timeout
	await _spawn_duck()
	ignore_shots = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if time_start > 0:
		time_now = Time.get_unix_time_from_system()
		time_elapsed = time_now - time_start
		# Inspired by https://ask.godotengine.org/3641/how-display-elapsed-time-in-game
		time_elapsed_min = int(time_elapsed / 60)
		time_elapsed_sec = int(time_elapsed) % 60
		# For details on GDScript string formatting, see
		# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_format_string.html#padding
		time_elapsed_string = str("%02d:%02d") % [time_elapsed_min, time_elapsed_sec]
		time_elapsed_label.text = time_elapsed_string
		#print("Time elapsed: " + time_elapsed_string)


func _show_highscore_screen():
	var _online_str = " local "
	if browser_game:
		_online_str = " online "
	print("Showing" + _online_str + "highscore screen")
	ignore_shots = true
	if duck:
		duck.queue_free()
	highscore_screen = highscore_node.instantiate()
	# Runs _ready() of HighscoreScreen()
	get_tree().current_scene.add_child(highscore_screen)
	highscore_screen.highscore_continued.connect(_on_highscore_continued)
	info_elements.hide()
	bg_music_player.stop()
	### Testing/debugging only
	if quick_debug_mode:
		score_current += 1234567
		#await get_tree().create_timer(2).timeout
	###
	await highscore_screen.init_highscore()
	await highscore_screen.check_if_new_highscore(score_current)
	if highscore_screen.continue_button:
		### Testing/debugging only
		#if quick_debug_mode:
		#	await get_tree().create_timer(2).timeout
		###
		highscore_screen.continue_button.show()
		await highscore_screen_continued


# Attention:
# If your overlay scenes/screens, like intro, credits, etc.
# contain a ColorRect object, for instance as a background box,
# then you need to set 'mouse_filter' (Inspector -> Mouse -> Filter)
# to 'Ignore' or 'Pass', otherwise input_event signals will get blocked
# for _all_ other nodes/objects in the tree, even if their layer is above
# the background box! This lost me hours of debugging!
#
# See the related GitHub issue #84796:
# https://github.com/godotengine/godot/issues/84796
func _show_intro_screen():
	print("Showing intro screen")
	ignore_shots = true
	info_elements.hide()
	version_label.show()
	intro_screen.show()
	(
			intro_screen.get_node("CreditsButton").pressed.
			connect(_on_credits_btn_pressed)
	)
	intro_screen.get_node("CreditsScreen").hide()
	(
			intro_screen.get_node("CreditsScreen/BackButton").pressed.
			connect(_on_credits_back_btn_pressed)
	)
	var _continue_label = intro_screen.get_node("ContinueLabel")
	_continue_label.hide()
	bg_atmosphere_player.stop()
	intro_screen_timer.start()
	await intro_screen_timer.timeout
	await _spawn_intro_screen_duck()
	_continue_label.show()
	_continue_label.position = Vector2(
			duck.position.x - _continue_label.size.x - 25,
			duck.position.y - (_continue_label.size.y * 0.5),
	)
	var _anim_player = intro_screen.get_node("AnimationPlayer")
	_anim_player.get_animation("blink_continue_text").set_loop_mode(true)
	_anim_player.play("blink_continue_text")
	await intro_screen_continued
	_anim_player.stop()
	_continue_label.hide()
	await _exit_intro_screen()


func _spawn_intro_screen_duck():
	duck = duck_node.instantiate()
	duck.show()
	duck.velocity = Vector2.ZERO
	var _viewport_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var _viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var _duck_width = ceil(duck.get_node("CollisionShape2D").get_shape().get_rect().size.x)
	var _duck_height = ceil(duck.get_node("CollisionShape2D").get_shape().get_rect().size.y)
	var _btn_x = _viewport_width - (_duck_width * 0.5) - 10
	var _btn_y = _viewport_height - (_duck_height * 0.5) - 10
	duck.position = Vector2(_btn_x, _btn_y)
	# Attention: This runs _ready() of Duck scene!
	intro_screen.add_child(duck)
	duck.wings_flap_player.stop()
	duck.duck_random_quack = false
	duck.input_pickable = true
	duck.next_duck.connect(_on_next_duck)


func _exit_intro_screen():
	# Attention: hide() will "kill" instantiated duck
	# (signal screen_exited())!
	intro_screen.hide()
	info_elements.show()
	version_label.hide()
	print("Leaving intro screen...")


func _on_highscore_continued():
	highscore_screen.hide()
	highscore_screen.queue_free()
	highscore_screen_continued.emit()
	print("Leaving highscore screen")


func _on_intro_screen_timeout() -> void:
	print(
			"Intro screen timer ran for " +
			str(intro_screen_timer.get_wait_time())
			+ " seconds"
	)


func _on_credits_btn_pressed():
	if duck:
		duck.input_pickable = false
	intro_screen.get_node("CreditsScreen").show()


func _on_credits_back_btn_pressed():
	intro_screen.get_node("CreditsScreen").hide()
	if duck:
		duck.input_pickable = true


func _init_labels():
	game_over_sign.hide()
	round_complete_sign.hide()
	round_start_sign.hide()
	duck_points_label.hide()
	version_label.hide()
	bullets_debug_label.visible = bullets_debug_label_show
	bullets_debug_label.text = str(bullets_current)
	round_label.text = round_label_prefix + str(round_current)
	score_label.text = str(score_current)
	time_elapsed_label.text = time_elapsed_string
	version_label.z_index=999
	version_label.text = str(
			"v" + ProjectSettings.get_setting("application/config/version")
	)
	print("Version info: " + version_label.text)


# Intro: Dog sniffs on ground, hears a duck and then jumps into the grass
# TODO: Refactor potentially redundant code with functions "_dog_laugh" and "_dog_present_duck"
func _dog_jump_into_grass():
	if dog_node.z_index < foreground.z_index:
		dog_node.z_index = foreground.z_index + 1
	dog_node.show()
	dog_node.get_node("AnimatedSprite2D").play("sniff")
	await get_tree().create_timer(2).timeout
	duck_quack_player.play()
	await get_tree().create_timer(0.3).timeout
	dog_node.get_node("AnimatedSprite2D").play("attention")
	dog_node.velocity = Vector2.ZERO
	await get_tree().create_timer(1).timeout
	# Attention:
	# Be careful when playing keyframe animations that change the position
	# of the contained AnimatedSprite2D and CollisionShape2D!
	# If you forget to also insert respective position keyframes for the
	# CollisionShape2D, you will get a strange difference in position
	# if you run the animation which can cost you _hours_ of debugging!
	# Trust me, I know it... :-/
	#print("dog_node.position: " + str(dog_node.position))
	dog_node.get_node("AnimationPlayer").play("jump_in_grass")
	#print("dog_node.position: " + str(dog_node.position))
	dog_node.get_node("CollisionShape2D").set_disabled(true)
	await get_tree().create_timer(0.1).timeout
	dog_node.get_node("DogBarkPlayer").play()
	await get_tree().create_timer(0.9).timeout
	dog_node.z_index = foreground.z_index - 1
	await get_tree().create_timer(0.55).timeout
	dog_node.hide()
	#print("dog_node.position: " + str(dog_node.position))
	dog_node.get_node("AnimationPlayer").play("RESET")
	#print("dog_node.position: " + str(dog_node.position))
	await get_tree().create_timer(1.5).timeout
	dog_node.get_node("CollisionShape2D").set_disabled(false)


# Game Over: Dog laughs at Player
# TODO: Refactor potentially redundant code with functions "_dog_present_duck" and "_dog_jump_into_grass"
func _dog_laugh():
	dog_node.hide()
	dog_node.velocity = Vector2.ZERO
	dog_node.get_node("AnimatedSprite2D").play("laugh")
	dog_node.get_node("CollisionShape2D").set_disabled(true)
	if dog_node.z_index >= foreground.z_index - 1:
		dog_node.z_index = foreground.z_index - 1
	# Determine x position for laughing dog at middle of viewport
	# See https://docs.godotengine.org/en/stable/classes/class_projectsettings.html
	var _viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	# Need to get best estimate of dog's height while presenting duck,
	# as default animation is "sniff" in which dog's height is much smaller.
	# This is needed to calculate how to hide dog inside grass.
	# Could be avoided by having seperate AnimatedSprite2D nodes in dog scene,
	# but this would make switching dog animations more complex.
	var _frame_count = (
			dog_node.get_node("AnimatedSprite2D").
			get_sprite_frames().get_frame_count("laugh")
	)
	var _last_frame = (
			dog_node.get_node("AnimatedSprite2D").
			get_sprite_frames().get_frame_texture("laugh", _frame_count-1)
	)
	var _dog_width = _last_frame.get_width()
	var _dog_height = _last_frame.get_height()
	# TODO: Make these multipliers configurable?
	var _dog_hidden_in_grass_y = foreground.region_rect.size.y + (_dog_height * 1.6)
	var _dog_hide_y_offset = _dog_height * 1.33
	#print("viewport_width: " + str(_viewport_width))
	#print("dog_width: " + str(_dog_width))
	#print("dog_height: " + str(_dog_height))
	#print("dog_hidden_in_grass_y: " + str(_dog_hidden_in_grass_y))
	#print("dog_hide_y_offset: " + str(_dog_hide_y_offset))
	var _new_x = roundi(_viewport_width * 0.5)
	var _new_y = roundi(_dog_hidden_in_grass_y)
	var _new_position = Vector2(_new_x, _new_y)
	#print("dog_node.position new: " + str(_new_position))
	# Dog slides up from new position
	# TODO: Move this into a function?
	dog_node.position = _new_position
	dog_node.get_node("DogLaughPlayer").play()
	dog_node.show()
	await get_tree().create_timer(0.5).timeout
	dog_node.velocity = Vector2(0, -1 * _dog_hide_y_offset)
	await get_tree().create_timer(0.5).timeout
	dog_node.velocity = Vector2.ZERO
	await get_tree().create_timer(2).timeout
	# Dog slides back down, avoiding collision
	# TODO: Move this into a function?
	dog_node.velocity = Vector2(0, _dog_hide_y_offset)
	await get_tree().create_timer(0.5).timeout
	dog_node.velocity = Vector2.ZERO
	dog_node.hide()
	dog_node.get_node("CollisionShape2D").set_disabled(false)
	await get_tree().create_timer(0.5).timeout


# Dog presents hit duck after it fell into grass
# TODO: Refactor potentially redundant code with functions "_dog_laugh" and "_dog_jump_into_grass"
func _dog_present_duck(_duck_hit_position, _duck_type):
	dog_node.hide()
	dog_node.velocity = Vector2.ZERO
	var _has_anim = (
			dog_node.get_node("AnimatedSprite2D").
			get_sprite_frames().
			has_animation("present_duck_" + _duck_type)
	)
	var _anim_name = "present_duck"
	if _has_anim:
		_anim_name = "present_duck_" + _duck_type
	if not _duck_type.is_empty() and _has_anim:
		dog_node.get_node("AnimatedSprite2D").play(_anim_name)
	dog_node.get_node("CollisionShape2D").set_disabled(true)
	if dog_node.z_index >= foreground.z_index - 1:
		dog_node.z_index = foreground.z_index - 1
	# Need to get best estimate of dog's height while presenting duck,
	# as default animation is "sniff" in which dog's height is much smaller.
	# This is needed to calculate how to hide dog inside grass.
	# Could be avoided by having seperate AnimatedSprite2D nodes in dog scene,
	# but this would make switching dog animations more complex.
	var _frame_count = (
			dog_node.get_node("AnimatedSprite2D").
			get_sprite_frames().get_frame_count("present_duck")
	)
	var _last_frame = (
			dog_node.get_node("AnimatedSprite2D").
			get_sprite_frames().get_frame_texture("present_duck", _frame_count-1)
	)
	var _dog_width = _last_frame.get_width()
	var _dog_height = _last_frame.get_height()
	# TODO: Make these multipliers configurable?
	var _dog_hidden_in_grass_y = foreground.region_rect.size.y + (_dog_height * 1.6)
	var _dog_hide_y_offset = _dog_height * 1.33
	#print("dog_width: " + str(_dog_width))
	#print("dog_height: " + str(_dog_height))
	#print("dog_hidden_in_grass_y: " + str(_dog_hidden_in_grass_y))
	#print("dog_hide_y_offset: " + str(_dog_hide_y_offset))
	var _new_x = roundi(_duck_hit_position.x)
	var _new_y = roundi(_dog_hidden_in_grass_y)
	var _new_position = Vector2(_new_x, _new_y)
	#print("dog_node.position new: " + str(_new_position))
	# Dog slides up from new position
	# TODO: Move this into a function?
	dog_node.position = _new_position
	dog_node.show()
	dog_node.velocity = Vector2(0, -1 * _dog_hide_y_offset)
	await get_tree().create_timer(0.5).timeout
	dog_node.velocity = Vector2.ZERO
	dog_node.get_node("DogBarkPlayer").play()
	await get_tree().create_timer(0.2).timeout
	# Dog slides back down, avoiding collision
	# TODO: Move this into a function?
	dog_node.velocity = Vector2(0, _dog_hide_y_offset)
	await get_tree().create_timer(0.5).timeout
	dog_node.velocity = Vector2.ZERO
	dog_node.hide()
	dog_node.get_node("CollisionShape2D").set_disabled(false)
	await get_tree().create_timer(0.5).timeout


# Create (spawn) a new duck with a random x position
# and a random direction angle 0 - 180°.
# The starting y position is inside the grass (below TopEdgeGrass'es y position),
# which is why we need to deactivate collision until the duck is in the air.
# Otherwise the duck would always bounce downwards and disappear.
#
# Attention:
# Assumes that TopEdgeGrass'es CollisionShape2D has one_way_collision enabled!
func _spawn_duck():
	top_edge_grass.get_node("CollisionShape2D").set_disabled(true)
	duck = duck_node.instantiate()
	duck.input_pickable = false
	duck.velocity = Vector2.ZERO
	duck.speed += duck_speed_round_multiplier * round_current
	duck.next_duck.connect(_on_next_duck)
	duck.hide()
	# Increase "randomness feeling" of duck types getting spawned by using a shuffle bag
	# See https://docs.godotengine.org/en/stable/tutorials/math/random_number_generation.html#better-randomness-using-shuffle-bags
	if duck_types_shuffle_bag.is_empty():
		duck_types_shuffle_bag = duck.duck_types.duplicate()
		duck_types_shuffle_bag.shuffle()
	var _random_duck = duck_types_shuffle_bag.pop_back()
	duck.current_duck_type = _random_duck
	duck.get_node("AnimatedSprite2D").play(_random_duck + duck.duck_fly_animation_suffix)
	var _viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var _duck_width = ceil(duck.get_node("CollisionShape2D").get_shape().get_rect().size.x)
	var _duck_height = ceil(duck.get_node("CollisionShape2D").get_shape().get_rect().size.y)
	var _duck_hidden_in_grass_y = floor(
			top_edge_grass.get_node("CollisionShape2D").position.y
			+ ceil(
					top_edge_grass.get_node("CollisionShape2D").get_shape().
					get_rect().size.y * 0.5
			)
	)
	var _new_x = randi_range(
			0 + (_duck_width * 0.5),
			_viewport_width - (_duck_width * 0.5),
	)
	var _new_y = _duck_hidden_in_grass_y
	var _new_position = Vector2(_new_x, _new_y)
	duck.position = _new_position
	#print("viewport_width: " + str(_viewport_width))
	#print("duck_width: " + str(_duck_width))
	#print("duck_height: " + str(_duck_height))
	#print("duck_hidden_in_grass_y: " + str(_duck_hidden_in_grass_y))
	#print("duck.position new: " + str(_new_position))
	# Attention: This runs _ready() of Duck scene!
	get_tree().current_scene.add_child(duck)
	duck.show()
	duck.velocity = duck.random_up_direction() * duck.speed
	duck.input_pickable = true
	top_edge_grass.get_node("CollisionShape2D").set_disabled(false)


# Function connected to "next_duck" signal from Duck scene
func _on_next_duck():
	var _duck_hit_position = duck.duck_hit_position
	var _duck_type = duck.current_duck_type
	if (
			game_over_timer.is_stopped()
			and not intro_screen.visible
	):
		ignore_shots = true
		_increase_ducks_shot()
		if show_duck_points:
			await _show_duck_points(_duck_hit_position)
		score_current += points_per_duck
		if present_hit_duck:
			await _dog_present_duck(_duck_hit_position, _duck_type)
		await _reload_shotgun()
		if ducks_shot == ducks_to_shoot_per_round:
			await _round_complete()
			await _start_next_round()
		await get_tree().create_timer(0.8).timeout
		await _spawn_duck()
		ignore_shots = false
	# Special case: intro screen continued (exited)
	elif intro_screen.visible:
		if (
				_duck_hit_position != Vector2.ZERO
				and intro_screen.get_node("ContinueLabel")
		):
			print("Intro screen duck shot")
			intro_screen.get_node("AnimationPlayer").stop()
			intro_screen.get_node("ContinueLabel").hide()
			if duck.get_node("CursorManager"):
				duck.get_node("CursorManager").set_default_cursor()
		await get_tree().create_timer(0.5).timeout
		intro_screen_continued.emit()
	# In all other cases: Do nothing.
	else:
		pass


func _show_duck_points(_duck_hit_position):
	bell_player.play()
	duck_points_label.text = str(points_per_duck)
	#print("duck_points_label.position: " + str(duck_points_label.position))
	duck_points_label.position = Vector2(
			roundi(_duck_hit_position.x - (duck_points_label.size.x/2)),
			roundi(_duck_hit_position.y - (duck_points_label.size.y * 0.75)),
	)
	#print("duck_points_label.position: " + str(duck_points_label.position))
	duck_points_label.z_index = 999
	duck_points_label.show()
	await get_tree().create_timer(show_duck_points_delay).timeout
	duck_points_label.hide()


func _start_next_round():
	round_complete_sign.hide()
	print("All " + str(ducks_to_shoot_per_round) + " ducks shot")
	print("Starting next round...")
	round_current += 1
	await _reset_ducks_shot()
	print("\nRound " + str(round_current))
	await _show_round_start_sign()
	if play_dog_intro:
		dog_node.position = dog_start_position
		#print("dog_node.position: " + str(dog_node.position))
		#print("dog_node.velocity: " + str(dog_node.velocity))
		dog_node.velocity = Vector2(1, 0) * dog_node.speed
		await _dog_jump_into_grass()


# Called on any sort of input.
# We're only interested in the action "left_click" though,
# which was defined in the Input Map in the project settings
# TODO: What action do we need for mobile devices?
func _input(event):
	if event.is_action_pressed("left_click"):
		var _credits_screen = intro_screen.get_node("CreditsScreen")
		# During normal game, enough bullets left
		if bullets_current >= 1 and not ignore_shots:
			shotgun_shot_player.play()
			_set_bullets(bullets_current - 1)
			# Attention:
			# Give the Duck scene a chance to check if duck was hit or not!
			# Otherwise the 3rd shot will never be able to hit a duck!
			await get_tree().create_timer(0.01).timeout
			# Prevent error "Invalid set index", by checking if duck still exists or not
			# See https://ask.godotengine.org/109379/invalid-index-visible-base-null-instance-with-value-type-bool
			# and https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-method-get-node-or-null
			var _duck_hit = false
			if get_node_or_null(NodePath("Duck")):
				_duck_hit = duck.duck_hit
			else:
				_duck_hit = true
			# If last shot fired without hit -> Game Over!
			if (
					bullets_current == 0
					and game_over_timer.is_stopped()
					and not _duck_hit
			):
				duck.input_pickable = false
				ignore_shots = true
				print("Last bullet shot without hit!")
				# Shots will be enabled again after game got reloaded by game over timeout...
				_game_over()
		# Intro screen exitable & credits not showing
		elif (
				intro_screen.visible
				and not info_elements.visible
				and intro_screen_timer.is_stopped()
				and not _credits_screen.visible
		):
			shotgun_shot_player.play()
		# Credits screen
		elif _credits_screen.visible:
			pass
		# Any situation in which shots are not desired,
		# but we want to give the player some feedback
		# (credits not showing)
		# Reminder: This case also applies to highscore screen
		else:
			shotgun_empty_player.play()
			await get_tree().create_timer(0.01).timeout


func _game_over():
	print("\nGAME OVER!")
	_dog_laugh()
	game_over_sign.show()
	game_over_player.play()
	if game_over_timer.is_stopped():
		print("wait_time from main scene: " + str (game_over_timer.wait_time))
		if game_over_timer.wait_time < game_over_timeout_sec_min:
			game_over_timer.wait_time = game_over_timeout_sec_min
			print("wait_time set to minimum: " + str (game_over_timer.wait_time))
		game_over_timer.start()


func _on_game_over_timeout():
	dog_node.get_node("DogLaughPlayer").stop()
	game_over_sign.hide()
	await _show_highscore_screen()
	# TODO: Refactor this to _start_next_round(), see what _ready() does different!
	print("Restarting game...\n")
	get_tree().reload_current_scene()


func _increase_ducks_shot():
	ducks_shot += 1
	### For debugging/testing only!
	if debug_round_mode and ducks_shot < ducks_to_shoot_per_round:
		ducks_shot = ducks_to_shoot_per_round
	###
	print("shot duck #" + str(ducks_shot))
	var _ducks_shot_region = ducks_shot_sprite.get_region_rect()
	if ducks_shot <= ducks_to_shoot_per_round:
		_ducks_shot_region = Rect2(
				_ducks_shot_region.position,
				Vector2(
						ducks_shot_sprite_default_width + (ducks_shot * ducks_shot_width),
						_ducks_shot_region.size.y,
				),
		)
		ducks_shot_sprite.set_region_rect(_ducks_shot_region)
	# TODO: Make this configurable?
	if ducks_shot == ducks_to_shoot_per_round:
		await get_tree().create_timer(1).timeout
	else:
		await get_tree().create_timer(0.5).timeout


func _reset_ducks_shot():
	ducks_shot = 0
	var _ducks_shot_region = ducks_shot_sprite.get_region_rect()
	_ducks_shot_region = Rect2(
			_ducks_shot_region.position,
			Vector2(
					1,
					_ducks_shot_region.size.y,
			)
	)
	ducks_shot_sprite.set_region_rect(_ducks_shot_region)


func _round_complete():
	success_player.play()
	var _bonus_pts = bonus_pts_per_round_multiplier * round_current
	var _round_complete_msg = round_complete_msg_prefix + format_score(str(_bonus_pts))
	round_complete_sign.get_node("Label").text = _round_complete_msg
	round_complete_sign.show()
	score_current += _bonus_pts
	if play_round_complete_animation:
		for i in range(round_compl_anim_blink_cnt):
			ducks_shot_sprite.hide()
			await get_tree().create_timer(round_compl_anim_blink_delay).timeout
			ducks_shot_sprite.show()
			await get_tree().create_timer(round_compl_anim_blink_delay).timeout
		ducks_shot_sprite.show()
		await get_tree().create_timer(round_compl_anim_blink_delay).timeout
	else:
		await get_tree().create_timer(1.5).timeout
	if success_player.is_playing():
		success_player.stop()
	round_complete_sign.hide()
	await get_tree().create_timer(round_complete_msg_delay_after).timeout


func _set_bullets(bullets_new):
	bullets_current = bullets_new
	print("bullets_current: " + str(bullets_current))
	var _bullets_region = bullets_sprite.get_region_rect()
	_bullets_region = Rect2(
		_bullets_region.position,
		Vector2(
			bullets_current * bullets_width,
			_bullets_region.size.y,
		)
	)
	bullets_sprite.set_region_rect(_bullets_region)


func _reload_shotgun():
	print("shotgun reload")
	_set_bullets(max_bullets)
	shotgun_reload_player.play()


func _show_round_start_sign():
	var _round_start_msg = round_start_msg_prefix + str(round_current)
	round_start_sign.get_node("Label").text = _round_start_msg
	round_start_sign.show()
	await get_tree().create_timer(round_start_msg_delay).timeout
	round_start_sign.hide()


# Format score with seperator every 3 digits
# Taken from:
# https://ask.godotengine.org/18559/how-to-add-commas-to-an-integer-or-float-in-gdscript?show=116174#a116174
func format_score(_score: String) -> String:
	var _i = _score.length() - 3
	while _i > 0:
		_score = _score.insert(_i, score_seperator)
		_i = _i - 3
	return _score
