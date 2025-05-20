extends Control

@onready var username: LineEdit = $Center/RegisterContainer/Username
@onready var email: LineEdit = $Center/RegisterContainer/Email
@onready var pasword: LineEdit = $Center/RegisterContainer/Pasword
@onready var register_btn: Button = $Center/RegisterContainer/Register
@onready var switch_login_btn: Button = $Center/RegisterContainer/SwitchLogin

func _ready() -> void:
	register_btn.pressed.connect(register)
	switch_login_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://menus/login/login_menu.tscn"))

func register():
	var res = await (Networking.http
		.http_post("/auth/register")
		.json({
		"username": username.text,
		"email": email.text,
		"password": pasword.text,
	}).send())
	
	if res.status() != 201:
		return
		
	get_tree().change_scene_to_file("res://menus/login/login_menu.tscn")
