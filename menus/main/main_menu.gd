extends Control

@onready var logout_btn: Button = $FooterMainSplit/Control/Logout
@onready var server_selector: OptionButton = $FooterMainSplit/Control/ServerSelector
@onready var refresh_btn: Button = $FooterMainSplit/Control/Refresh
@onready var play_btn: Button = $FooterMainSplit/Control/Play

@onready var create_class_btn: Button = $FooterMainSplit/Main/VSplitContainer/ClassSelector/CreateClass
@onready var classes_container: HBoxContainer = $FooterMainSplit/Main/VSplitContainer/ClassSelector/Classes

@onready var class_creator: CenterContainer = $ClassCreator
@onready var class_creator_back: Button = $ClassCreator/Form/Back
@onready var class_creator_name_input: LineEdit = $ClassCreator/Form/Name
@onready var class_creator_class_input: OptionButton = $ClassCreator/Form/Class
@onready var class_creator_submit_btn: Button = $ClassCreator/Form/Create

const CLASS_SELECTOR = preload("res://menus/main/class_selector/class_selector.tscn")

var servers: Array = []

func _ready() -> void:
	refresh_btn.pressed.connect(request_servers)
	logout_btn.pressed.connect(logout)
	play_btn.pressed.connect(play)
	class_creator.visible = false
	
	create_class_btn.pressed.connect(
		func(): 
			class_creator.visible = true
			clear_create_class_inputs()
			)
		
	class_creator_back.pressed.connect(
		func(): 
			class_creator.visible = false
			clear_create_class_inputs()
			)
			
	class_creator_submit_btn.pressed.connect(
		func():
			create_class()
			class_creator.visible = false
			clear_create_class_inputs()
	)

	await get_classes()
	await request_servers()
	update_create_class_btn_visibility()

func clear_create_class_inputs():
	class_creator_name_input.text = ""
	class_creator_class_input.select(0)

func create_class():
	var n = class_creator_name_input.text
	var cname = class_creator_class_input.get_item_text(class_creator_class_input.selected)
	
	var resp = await (Networking.http
		.http_post("/profile")
		.header("session-id", Networking.session_id)
		.json({
			"name": n,
			"class": cname
		})
		.send())
	
	if resp.status() != 201:
		return
		
	var c = (await resp.json())["data"]
	create_class_selector(c["name"], c["class"], c["id"])
	update_create_class_btn_visibility()

func update_create_class_btn_visibility():
	create_class_btn.visible = classes_container.get_child_count() < 3
		
func get_classes():
	var resp = await (Networking.http.http_get("/profile/" + Networking.user_id).send())
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
	inst.deleted.connect(
		func(id: String): 
			create_class_btn.visible = true
			if id == Networking.profile_id:
				Networking.profile_id = null
	)
	inst.selected.connect(
		func(id: String):
			for child in classes_container.get_children():
				child.is_selected = child.id == id
	)
	classes_container.add_child(inst)

func request_servers():
	server_selector.clear()
	var resp = await (Networking.http
		.http_get("/browser")
		.send())
	
	if resp.status() != 200: return
	
	var json = await resp.json()
	servers = json["data"]
	for server in servers:
		server_selector.add_item(server["name"])
	
func play():
	if server_selector.selected == -1: return
	if Networking.profile_id == null: return
	
	get_tree().change_scene_to_file("res://levels/hub/hub.tscn")
	var server = servers[server_selector.selected]
	Client.connect_to_server(server["ip"], server["port"])

func logout():
	DirAccess.remove_absolute(Networking.SESSION_ID_FILE)
	get_tree().change_scene_to_file("res://menus/login/login_menu.tscn")
