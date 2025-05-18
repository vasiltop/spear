extends Control

const REGISTER_MENU = preload("res://menus/register/register_menu.tscn")
const MAIN_MENU = preload("res://menus/main/main_menu.tscn")

@onready var username: LineEdit = $VBoxContainer/Username
@onready var pasword: LineEdit = $VBoxContainer/Pasword
@onready var login_btn: Button = $VBoxContainer/Login
@onready var switch_register_btn: Button = $VBoxContainer/SwitchRegister
@onready var http_request: HTTPRequest = $HTTPRequest

func _ready() -> void:
	#if FileAccess.file_exists(Global.SESSION_ID_FILE):
	#	get_tree().change_scene_to_packed(MAIN_MENU)
	#	return
	
	login_btn.pressed.connect(login)
	switch_register_btn.pressed.connect(func(): get_tree().change_scene_to_packed(REGISTER_MENU))
	http_request.request_completed.connect(request_completed)
	
func request_completed(result, response_code, headers, body):
	if response_code != 200: return
	var json = JSON.parse_string(body.get_string_from_utf8())
	print(json["session_id"])

func login():
	var data = {
		"username": username.text,
		"password": pasword.text,
	}
	
	var json = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	http_request.request(Global.URL + "/auth/login", headers, HTTPClient.METHOD_POST, json)
