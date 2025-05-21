extends Control

@onready var username: LineEdit = $Center/LoginContainer/Username
@onready var pasword: LineEdit = $Center/LoginContainer/Pasword
@onready var login_btn: Button = $Center/LoginContainer/Login
@onready var switch_register_btn: Button = $Center/LoginContainer/SwitchRegister

func _ready() -> void:
	var args = Array(OS.get_cmdline_args())
	if len(args) > 1: return
	
	if FileAccess.file_exists(Networking.SESSION_ID_FILE):
		var file = FileAccess.open(Networking.SESSION_ID_FILE, FileAccess.READ)
		var content = file.get_as_text()
		Networking.session_id = content
		
		var res = await (Networking.http.http_get("/auth/me").header("session-id", Networking.session_id).send())
		print(res.status())
		if res.status() == 200:
			Networking.user_id = (await res.json())["user_id"]
		
		get_tree().change_scene_to_file("res://menus/main/main_menu.tscn")
	
	login_btn.pressed.connect(login)
	switch_register_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://menus/register/register_menu.tscn"))

func login():
	var resp = await (Networking.http
		.http_post("/auth/login")
		.json({
		"username": username.text,
		"password": pasword.text,
	}).send())
	
	if resp.status() != 200:
		return
		
	var res = await resp.json()
	var id = res["session_id"]
	Networking.session_id = id
	
	var file = FileAccess.open(Networking.SESSION_ID_FILE, FileAccess.WRITE)
	file.store_string(id)
	
	get_tree().change_scene_to_file("res://menus/main/main_menu.tscn")
