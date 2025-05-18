extends Control

@onready var username: LineEdit = $VBoxContainer/Username
@onready var email: LineEdit = $VBoxContainer/Email
@onready var pasword: LineEdit = $VBoxContainer/Pasword
@onready var register_btn: Button = $VBoxContainer/Register
@onready var switch_login_btn: Button = $VBoxContainer/SwitchLogin
@onready var http_request: HTTPRequest = $HTTPRequest

func _ready() -> void:
	register_btn.pressed.connect(register)
	switch_login_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://menus/login/login_menu.tscn"))
	http_request.request_completed.connect(request_completed)
	
func request_completed(result, response_code, headers, body):
	if response_code != 201: return
	get_tree().change_scene_to_file("res://menus/login/login_menu.tscn")

func register():
	var data = {
		"username": username.text,
		"email": email.text,
		"password": pasword.text,
	}
	
	var json = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	http_request.request(Global.URL + "/auth/register", headers, HTTPClient.METHOD_POST, json)
