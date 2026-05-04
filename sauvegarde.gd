# SaveManager.gd
extends Node

const SAVE_PATH = "user://save_data.cfg" # "user://" est un dossier persistant sur la carte SD
var config = ConfigFile.new()

func save_installation_status(game_id, status):
	config.load(SAVE_PATH)
	config.set_value("installed_games", game_id, status)
	config.save(SAVE_PATH)

func is_game_installed(game_id):
	var err = config.load(SAVE_PATH)
	if err != OK:
		return false
	return config.get_value("installed_games", game_id, false)
