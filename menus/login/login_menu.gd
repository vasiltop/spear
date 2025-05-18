extends Control

@onready var username: LineEdit = $VBoxContainer/Username
@onready var pasword: LineEdit = $VBoxContainer/Pasword
@onready var login_btn: Button = $VBoxContainer/Login
@onready var switch_register_btn: Button = $VBoxContainer/SwitchRegister
@onready var http_request: HTTPRequest = $HTTPRequest

func _ready() -> void:
	if FileAccess.file_exists(Global.SESSION_ID_FILE):
		var file = FileAccess.open(Global.SESSION_ID_FILE, FileAccess.READ)
		var content = file.get_as_text()
		Global.session_id = content
		get_tree().change_scene_to_file("res://menus/main/main_menu.tscn")
	
	login_btn.pressed.connect(login)
	switch_register_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://menus/register/register_menu.tscn"))
	http_request.request_completed.connect(request_completed)
	
func request_completed(result, response_code, headers, body):
	if response_code != 200: return
	var json = JSON.parse_string(body.get_string_from_utf8())
	var file = FileAccess.open(Global.SESSION_ID_FILE, FileAccess.WRITE)
	var id = json["session_id"]
	file.store_string(id)
	Global.session_id = id
	get_tree().change_scene_to_file("res://menus/main/main_menu.tscn")

func login():
	var data = {
		"username": username.text,
		"password": pasword.text,
	}
	
	var json = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	http_request.request(Global.URL + "/auth/login", headers, HTTPClient.METHOD_POST, json)
