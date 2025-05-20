extends Node

const BROWSER_PING_TIME: float = 30.0

var timer: float = BROWSER_PING_TIME

var address: String
var port: int
var sname: String
var max_players: int

enum ServerType {
	HUB,
	GAME
}

var type: ServerType

func _ready() -> void:
	var args = Array(OS.get_cmdline_args())
	set_process(false)
	
	if len(args) > 1:
		set_process(true)
		address = args[1]
		port = int(args[2])
		sname = args[3]
		type = ServerType.HUB if args[4] == "hub" else ServerType.GAME
		
		max_players = 64 if type == ServerType.HUB else 4
		init_server()
		
		if type == ServerType.HUB:
			get_tree().change_scene_to_file("res://levels/hub/hub.tscn")
		else:
			get_tree().change_scene_to_file("res://levels/dungeon/dungeon.tscn")

func init_server():
	print("Creating server %s on address: %s" % [sname, (address + ":" + str(port))])
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(port, 64)
	Networking.multiplayer.multiplayer_peer = peer

func _process(delta: float) -> void:
	timer += delta
	if timer >= BROWSER_PING_TIME:
		timer = 0
		ping_server_browser()
		
func ping_server_browser():
	await (Networking.http
		.http_post("/browser")
		.json({
			"ip": address,
			"port": port,
			"name": sname
		}).send())
