extends Node

const SCENES := {
	"login_menu": "res://src/menus/login/login_menu.tscn",
	"register_menu": "res://src/menus/register/register_menu.tscn",
	"main_menu": "res://src/menus/main/main_menu.tscn",
	"game": "res://src/levels/game/game.tscn",
}

func change(scene_name: String) -> void:
	get_tree().change_scene_to_file(str(SCENES[scene_name]))
