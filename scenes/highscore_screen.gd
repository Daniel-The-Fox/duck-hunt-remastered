extends CanvasLayer

#####################################
# DUCK HUNT REMASTERED              #
# A fan game by Daniel the Fox      #
# https://danielthefox.itch.io      #
# https://github.com/Daniel-The-Fox #
#####################################


# Signals emitted by this script
signal highscore_continued
signal player_name_saved


# Constants used in this script
const SILENT_WOLF_KEY_FILE = "res://silent_wolf_api_key.dat"
const HIGHSCORE_FILE_PATH = "user://highscore.dat"
const NUMBER_OF_PLAYERS = 7
const SCORE_SEPERATOR = ","


# Initialize nodes used in this script
@onready var continue_button = $Highscore/ContinueButton
@onready var highscore = $Highscore
@onready var highscore_h_box = $Highscore/BoxContainer/MarginContainer/HighscoreHBox
@onready var high_score_title_label = $Highscore/HighScoreTitleLabel
@onready var loading = $Loading
@onready var player_name_input = $PlayerNameInput
@onready var player_name_input_field = $PlayerNameInput/CanvasGroup/PlayerNameInputField
@onready var player_name_v_box = $Highscore/BoxContainer/MarginContainer/HighscoreHBox/PlayerNameVBox
@onready var position_v_box = $Highscore/BoxContainer/MarginContainer/HighscoreHBox/PositionVBox
@onready var score_v_box = $Highscore/BoxContainer/MarginContainer/HighscoreHBox/ScoreVBox


# Variables used by this script
var highscore_dict: Dictionary = {}
var player_name = ""
var online_highscore = OS.has_feature("web")
var online_highscore_config_success = false
var online_str = (" online ") if online_highscore else (" local ")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	continue_button.hide()
	player_name_input.hide()
	await _enable_loading()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func init_highscore():
	await set_position_defaults()
	await reset_highscore()
	await update_highscore_screen()
	if online_highscore:
		print("Game is running in a web browser!")
		high_score_title_label.text = "Online " + high_score_title_label.text
		await _configure_online_highscore()
	else:
		high_score_title_label.text = "Local " + high_score_title_label.text
	print("online_highscore_config_success: " + str(online_highscore_config_success))
	if (
			(online_highscore and online_highscore_config_success)
			or not online_highscore
	):
		await load_highscore()
		await update_highscore_screen()
	await _disable_loading()


func check_if_new_highscore(_score_int: int = 0):
	if online_highscore and not online_highscore_config_success:
		return false
	print(
			"checking if score is a new" + online_str +
			"highscore: " + str(_score_int)
	)
	if _score_int > 0:
		var _is_new_highscore = false
		var _highscore_dict_new: Dictionary = {}
		for _i in range(1, NUMBER_OF_PLAYERS + 1):
			if highscore_dict.has("player_" + str(_i)):
				if (
						_score_int > int(highscore_dict["player_" + str(_i)]["score"])
						and not _is_new_highscore
				):
					print("New" + online_str + "highscore! :)")
					_is_new_highscore = true
					await _get_player_name_input()
					_highscore_dict_new["player_" + str(_i)] = {
						"name": player_name,
						"score": _score_int,
					}
				elif _is_new_highscore:
					_highscore_dict_new["player_" + str(_i)] = (
							highscore_dict["player_" + str(_i - 1)]
					)
				else:
					_highscore_dict_new["player_" + str(_i)] = (
							highscore_dict["player_" + str(_i)]
					)
		if _is_new_highscore:
			highscore_dict = _highscore_dict_new.duplicate()
			await _enable_loading()
			await update_highscore_screen()
			await save_highscore()
			await _disable_loading()


# Format score with seperator every 3 digits
# Taken from:
# https://ask.godotengine.org/18559/how-to-add-commas-to-an-integer-or-float-in-gdscript?show=116174#a116174
func format_score(_score: String) -> String:
	var _len = _score.length() - 3
	while _len > 0:
		_score = _score.insert(_len, SCORE_SEPERATOR)
		_len = _len - 3
	return _score


func load_highscore():
	if online_highscore:
		await load_online_highscore()
	else:
		await load_offline_highscore()
	await print_highscore()


func load_offline_highscore():
	if not FileAccess.file_exists(HIGHSCORE_FILE_PATH):
		print("Highscore file didn't exist yet. Creating it at '" + HIGHSCORE_FILE_PATH + "'")
		var _highscore_file = FileAccess.open(HIGHSCORE_FILE_PATH, FileAccess.WRITE)
		_highscore_file.close()
		reset_highscore()
		return true
	print("Loading highscore from '" + HIGHSCORE_FILE_PATH + "'")
	var _highscore_file = FileAccess.open(HIGHSCORE_FILE_PATH, FileAccess.READ)
	var _json_string = _highscore_file.get_as_text()
	var json = JSON.new()
	var _parse_result = json.parse(_json_string)
	if not _parse_result == OK:
		print(
				"JSON Parse Error: ", json.get_error_message(), " in ",
				_json_string, " at line ", json.get_error_line()
		)
	var _json_data = json.get_data()
	if _json_data:
		for _i in range(1, NUMBER_OF_PLAYERS + 1):
			if _json_data.has("player_" + str(_i)):
				highscore_dict["player_" + str(_i)] = _json_data["player_" + str(_i)]
			else:
				highscore_dict["player_" + str(_i)] = {
					"name": "",
					"score": 0,
				}
	else:
		print("Highscore file '" + HIGHSCORE_FILE_PATH + "' is empty!")
		return false
	return true


func load_online_highscore():
	print("Loading online highscore...")
	var sw_result: Dictionary = (
			await SilentWolf.Scores.
			get_scores(NUMBER_OF_PLAYERS).sw_get_scores_complete
	)
	print("SilentWolf Scores: " + str(sw_result.scores))
	var _i = 1
	for score in sw_result.scores:
		if _i <= NUMBER_OF_PLAYERS:
			if len(score.player_name) > 1 and score.score > 0:
				highscore_dict["player_" + str(_i)] = {
					"name": score.player_name,
					"score": score.score,
				}
			else:
				highscore_dict["player_" + str(_i)] = {
					"name": "",
					"score": 0,
				}
		_i += 1


func reset_highscore():
	for _i in range(1, NUMBER_OF_PLAYERS + 1):
		highscore_dict["player_" + str(_i)] = {
			"name": "",
			"score": 0,
		}


func save_highscore():
	if online_highscore:
		await save_online_highscore()
	else:
		await save_offline_highscore()
	await print_highscore()


func save_offline_highscore():
	print("Saving highscore to '" + HIGHSCORE_FILE_PATH + "'")
	var _highscore_file = FileAccess.open(HIGHSCORE_FILE_PATH, FileAccess.WRITE)
	var _json_string = JSON.stringify(highscore_dict)
	_highscore_file.store_line(_json_string)
	_highscore_file.close()


func save_online_highscore():
	print("Saving online highscore")
	for _i in range(1, NUMBER_OF_PLAYERS + 1):
		if highscore_dict.has("player_" + str(_i)):
			if (
					len(highscore_dict["player_" + str(_i)]["name"]) > 1
					and highscore_dict["player_" + str(_i)]["score"] > 0
			):
				await SilentWolf.Scores.save_score(
						highscore_dict["player_" + str(_i)]["name"],
						str(highscore_dict["player_" + str(_i)]["score"]),
				)


func set_position_defaults():
	for _i in range(1, NUMBER_OF_PLAYERS + 1):
		position_v_box.get_node("Position" + str(_i)).text = "#" + str(_i)


func set_name_dummy_values():
	player_name_v_box.get_node("Name1").text = "LongPlayerName"
	player_name_v_box.get_node("Name2").text = "Name"
	player_name_v_box.get_node("Name3").text = "ABitLonger"
	player_name_v_box.get_node("Name4").text = "AReaaallyLongName"
	player_name_v_box.get_node("Name5").text = "ShortName"
	player_name_v_box.get_node("Name6").text = "AReallyMuchTooLongPlayerName"
	player_name_v_box.get_node("Name7").text = "Shorty"


func set_score_dummy_values():
	score_v_box.get_node("Score1").text = "9,999,999"
	score_v_box.get_node("Score2").text = "3,456,789"
	score_v_box.get_node("Score3").text = "123,456"
	score_v_box.get_node("Score4").text = "6,750"
	score_v_box.get_node("Score5").text = "999"
	score_v_box.get_node("Score6").text = "66"
	score_v_box.get_node("Score7").text = "0"


func update_highscore_screen():
	print("Updating" + online_str + "highscore screen...")
	for _i in range(1, NUMBER_OF_PLAYERS + 1):
		if highscore_dict.has("player_" + str(_i)):
			player_name_v_box.get_node("Name" + str(_i)).text = (
					highscore_dict["player_" + str(_i)]["name"]
			)
			score_v_box.get_node("Score" + str(_i)).text = (
					format_score(str(highscore_dict["player_" + str(_i)]["score"]))
			)


func print_highscore():
	for _i in range(1, NUMBER_OF_PLAYERS + 1):
		if highscore_dict.has("player_" + str(_i)):
			print(
					"player_" + str(_i) + ": " +
					str(highscore_dict["player_" + str(_i)])
			)


func _get_player_name_input():
	player_name_input.show()
	player_name_input_field.text = _get_random_player_name()
	await player_name_saved
	player_name_input.hide()


func _get_random_player_name():
	var _rnd_name = RandomPlayerName.new()
	var _random_player_name = _rnd_name.get_random_player_name()
	print("random player name: " + _random_player_name)
	return _random_player_name


func _on_continue_button_pressed() -> void:
	highscore_continued.emit()


func _on_regenerate_name_pressed() -> void:
	player_name_input_field.text = _get_random_player_name()


func _on_save_button_pressed() -> void:
	player_name = player_name_input_field.text
	player_name_saved.emit()


# Expects Silent Wolf key file at SILENT_WOLF_KEY_FILE (i.e. res://silent_wolf_key.dat)
# The key file should contain two key, value pairs
# "silent_wolf_api_key": "<Your Silent Wolf API key>",
# "silent_wolf_game_id": "<Your Silent Wolf game id>"
func _configure_online_highscore():
	var _sw_api_key = ""
	var _sw_game_id = ""
	if not FileAccess.file_exists(SILENT_WOLF_KEY_FILE):
		print(
				"ERROR: Silent Wolf key file expected at '" +
				SILENT_WOLF_KEY_FILE + "' doesn't exist!"
		)
		return false
	var _sw_key_file = FileAccess.open(SILENT_WOLF_KEY_FILE, FileAccess.READ)
	var _sw_key_json_str = _sw_key_file.get_as_text()
	var _sw_json = JSON.new()
	var _sw_key_parse_res = _sw_json.parse(_sw_key_json_str)
	if not _sw_key_parse_res == OK:
		print(
				"JSON Parse Error: ", _sw_json.get_error_message(), " in ",
				_sw_key_json_str, " at line ", _sw_json.get_error_line()
		)
	var _sw_key_json_data = _sw_json.get_data()
	if _sw_key_json_data:
		if _sw_key_json_data.has("silent_wolf_api_key"):
			_sw_api_key = _sw_key_json_data["silent_wolf_api_key"]
		else:
			print(
					"ERROR: Silent Wolf key file located at '" +
					SILENT_WOLF_KEY_FILE +
					"' doesn't contain the key 'silent_wolf_api_key'!"
			)
			return false
		if _sw_key_json_data.has("silent_wolf_game_id"):
			_sw_game_id = _sw_key_json_data["silent_wolf_game_id"]
		else:
			print(
					"ERROR: Silent Wolf key file located at '" +
					SILENT_WOLF_KEY_FILE +
					"' doesn't contain the key 'silent_wolf_game_id'!"
			)
			return false
	else:
		print(
				"ERROR: Silent Wolf key file located at '" +
				SILENT_WOLF_KEY_FILE + "' is empty!"
		)
		return false
	# See https://silentwolf.com/leaderboard
	# amount of logging in the console from SilentWolf
	# 0 for errors only,
	# 1 for info-level logging and
	# 2 for debug logging
	print(_sw_api_key)
	print(_sw_game_id)
	if len(_sw_api_key) > 3 and len(_sw_game_id) > 3:
		var _sw_auth_success = await SilentWolf.configure({
				"api_key": _sw_api_key,
				"game_id": _sw_game_id,
				"log_level": 0,
		})
		print("_sw_auth_success: " + str(_sw_auth_success))
	else:
		print(
				"Unexpected error while reading and applying Silent Wolf key file at '" +
				SILENT_WOLF_KEY_FILE + "'!"
		)
		return false
	online_highscore_config_success = true
	return true


func _enable_loading():
	highscore.hide()
	loading.show()


func _disable_loading():
	loading.hide()
	highscore.show()
