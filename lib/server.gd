extends Node

const BROWSER_PING_TIME: float = 30.0
const PORT: int = 8000

var timer: float = BROWSER_PING_TIME
var http_request: HTTPRequest = HTTPRequest.new()

func _ready() -> void:
	add_child(http_request)
	var args = Array(OS.get_cmdline_args())

	if args.has("-server"):
		init_server()

func init_server():
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, 64)
	multiplayer.multiplayer_peer = peer

func _process(delta: float) -> void:
	if not multiplayer.is_server(): return
	timer += delta
	print(timer)
	if timer >= BROWSER_PING_TIME:
		timer = 0
		ping_server_browser()
		
func ping_server_browser():
	var data = {
		"ip": "127.0.0.1",
		"port": PORT,
		"name": "LOCAL"
	}

	var json = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	http_request.request(Global.URL + "/browser", headers, HTTPClient.METHOD_POST, json)
	print("pinged")
