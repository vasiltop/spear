class_name LoginMenu extends CenterContainer

@onready var _username_input: LineEdit = $Content/Username
@onready var _password_input: LineEdit = $Content/Password
@onready var _login_btn: Button = $Content/Login
@onready var _switch_btn: Button = $Content/Switch

func _ready() -> void:
	_login_btn.pressed.connect(_login)
	
	if FileAccess.file_exists(Networking.SESSION_ID_FILE):
		var file := FileAccess.open(Networking.SESSION_ID_FILE, FileAccess.READ)
		Networking.session_id = file.get_as_text()
		var res := await (Networking.http_client.http_get("/auth/me").header("session-id", Networking.session_id).send())
		
		if res.status() != 200: return
		
		Networking.user_id = (await res.json()).user_id
		SceneManager.change("main_menu")
	
func _login() -> void:
	var res := await Networking.http_client.http_post("/auth/login").json({
		"username": _username_input.text,
		"password": _password_input.text,
	}).send()
	
	if res.status() != 200: return
	
	var json: Dictionary = await res.json()
	var id: String = json.session_id
	Networking.session_id = id
	
	var file := FileAccess.open(Networking.SESSION_ID_FILE, FileAccess.WRITE)
	file.store_string(id)
	SceneManager.change("main_menu")
