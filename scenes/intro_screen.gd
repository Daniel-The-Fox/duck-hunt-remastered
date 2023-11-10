extends CanvasLayer

#####################################
# DUCK HUNT REMASTERED              #
# A fan game by Daniel the Fox      #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# RichTextLabel's meta_clicked signal was connected to this function
# top open URLs clicked in the credits text
# See https://docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html
func _richtextlabel_on_meta_clicked(meta):
	# meta is not guaranteed to be a String, so convert it to a String
	# to avoid script errors at run-time.
	OS.shell_open(str(meta))
