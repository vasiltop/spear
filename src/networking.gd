extends Node

@onready var http_client := BetterHTTPClient.new(self, BetterHTTPURL.parse(API_URL))

const API_URL := "http://157.230.69.243:3000"
const SESSION_ID_FILE: String = "user://session.txt"
const MAX_SERVER_SIZE := 10
const SERVER_BROWSER_PING_INTERVAL := 60

var _server_browser_ping_timer: BetterTimer
var _address: String
var _port: int
var _name: String

var object_counter: int
var session_id: String
var user_id: String

func next_object_id() -> int:
	object_counter += 1
	return object_counter

func _ready() -> void:
	if _try_create_server(): return
		
func _ping_server_browser() -> void:
	await (http_client
		.http_post("/browser")
		.json({
			"ip": _address,
			"port": _port,
			"name": _name,
		}).send())

func _try_create_server() -> bool:
	var args := OS.get_cmdline_args()
	if not len(args) > 1: return false
	
	var i := 0
	
	while i < args.size():
		if args[i] == "==":
			_address = args[i + 1]
			_port = int(args[i + 2])
			_name = args[i + 3]
			break
		i += 1

	_create_server()
	_server_browser_ping_timer = BetterTimer.new(self, SERVER_BROWSER_PING_INTERVAL, _ping_server_browser)
	_server_browser_ping_timer.start()
	SceneManager.change("game")
	
	return true

func _create_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(_port, self.MAX_SERVER_SIZE)
	multiplayer.multiplayer_peer = peer

func create_client(address: String, port: int) -> void:
	print(address, port)
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
