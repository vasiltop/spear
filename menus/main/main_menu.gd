extends Control

@onready var logout_button: Button = $Logout
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var server_selector: OptionButton = $ServerSelector
@onready var play_btn: Button = $Play
@onready var refresh_btn: Button = $Refresh

var servers: Array = []

func _ready() -> void:
	logout_button.pressed.connect(logout)
	http_request.request_completed.connect(request_completed)
	refresh_btn.pressed.connect(request_servers)
	request_servers()
	play_btn.pressed.connect(play)

func request_servers():
	http_request.request(Networking.API_URL + "/browser")

func play():
	get_tree().change_scene_to_file("res://levels/hub/hub.tscn")
	var server = servers[server_selector.selected]
	Client.connect_to_server(server["ip"], server["port"])

func logout():
	DirAccess.remove_absolute(Networking.SESSION_ID_FILE)
	get_tree().change_scene_to_file("res://menus/login/login_menu.tscn")

func request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	servers = json["data"]
	server_selector.clear()
	
	for server in servers:
		server_selector.add_item(server["name"])
