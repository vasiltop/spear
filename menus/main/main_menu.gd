extends Control

@onready var logout_button: Button = $Logout
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var server_selector: OptionButton = $ServerSelector
@onready var play_btn: Button = $Play
@onready var refresh_btn: Button = $Refresh
@onready var classes_container: HBoxContainer = $Classes/Classes
@onready var create_class_btn: Button = $Classes/Creator/Create
@onready var name_input: LineEdit = $Classes/Creator/Name
@onready var class_input: OptionButton = $Classes/Creator/OptionButton

const CLASS_SELECTOR = preload("res://menus/main/class_selector/class_selector.tscn")

var servers: Array = []

func _ready() -> void:
	http_request.request_completed.connect(request_completed)
	
	refresh_btn.pressed.connect(request_servers)
	logout_button.pressed.connect(logout)
	play_btn.pressed.connect(play)
	create_class_btn.pressed.connect(create_class)

	get_classes()
	request_servers()

func create_class():
	var n = name_input.text
	var cname = class_input.get_item_text(class_input.selected)
	
	var resp = await (Networking.http
		.http_post("/class")
		.header("session-id", Networking.session_id)
		.json({
			"name": n,
			"class": cname
		})
		.send())
	
	print(resp.status())
	if resp.status() != 201:
		return
		
	var c = (await resp.json())["data"]
	create_class_selector(c["name"], c["class"], c["id"])

func get_classes():
	var resp = await (Networking.http
		.http_get("/class")
		.header("session-id", Networking.session_id)
		.send())
	
	if resp.status() != 200:
		return
		
	var classes = await resp.json()
	
	for c in classes["data"]:
		create_class_selector(c["name"], c["class"], c["id"])

func create_class_selector(n, c, id):
	var inst = CLASS_SELECTOR.instantiate()
	inst.char_name = n
	inst.char_class = c
	inst.id = id
	classes_container.add_child(inst)

func request_servers():
	http_request.request(Networking.API_URL + "/browser")

func play():
	if server_selector.selected == -1: return
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
