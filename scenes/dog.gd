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


# Initialize nodes used in script
@onready var dog_sprite = $AnimatedSprite2D


# General settings and status variables
var speed: float = 30.0


func _ready():
	dog_sprite.play()
	input_pickable = false
	velocity = Vector2(1, 0) * speed


func _physics_process(delta):
	var _dog_collision = move_and_collide(velocity * delta)
	if _dog_collision:
		velocity = velocity.bounce(_dog_collision.get_normal())
	var is_left = velocity.x < 0
	dog_sprite.flip_h = is_left
