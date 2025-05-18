extends Control

@onready var logout_button: Button = $Logout
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var server_selector: OptionButton = $ServerSelector
@onready var play_btn: Button = $Play

var servers: Array = []

func _ready() -> void:
	logout_button.pressed.connect(logout)
	http_request.request_completed.connect(request_completed)
	http_request.request(Global.URL + "/browser")
	play_btn.pressed.connect(play)

func play():
	var server = servers[server_selector.selected]
	print(server)

func logout():
	DirAccess.remove_absolute(Global.SESSION_ID_FILE)
	get_tree().change_scene_to_file("res://menus/login/login_menu.tscn")

func request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	servers = json["data"]
	server_selector.clear()
	
	for server in servers:
		server_selector.add_item(server["name"])
