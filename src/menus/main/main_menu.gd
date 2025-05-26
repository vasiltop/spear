class_name MainMenu extends CenterContainer

@onready var _server_refresh_timer := BetterTimer.new(self, SERVER_BROWSER_PING_INTERVAL, _refresh_server_browser)
@onready var _servers_container: VBoxContainer = $Content/Scroll/Servers

const SERVER_BROWSER_PING_INTERVAL := 1
const ServerButton = preload("res://src/menus/main/server.tscn")

func _ready() -> void:
	_server_refresh_timer.start()
	multiplayer.connected_to_server.connect(func() -> void: SceneManager.change("game"))

func _refresh_server_browser() -> void:
		var res := await Networking.http_client.http_get("/browser").send()
		var servers: Array = (await res.json()).data
		
		for child in _servers_container.get_children():
			child.queue_free()
			
		for server: Dictionary in servers:
			var inst: Server = ServerButton.instantiate()
			_servers_container.add_child(inst)
			inst.init(str(server.ip), server.port as int, str(server.name))
