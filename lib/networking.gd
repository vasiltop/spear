extends Node

signal player_connected(id: int)

const API_URL: String = "http://localhost:3000"
const SESSION_ID_FILE: String = "user://session.dat"

@onready var http: BetterHTTPClient = BetterHTTPClient.new(self, BetterHTTPURL.parse(API_URL))

var session_id: String = ""
var user_id: String = ""
var profile_id = null

var players = {
# example:
#	-1: {
#		"session_id": "",
#		"profile_id": "",
#		"node": null,
#		"init": false
#	}
}

func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	
func peer_connected(id: int):
	print(id(), ": Connected to peer ", id)
	
	if is_server():
		spawn_player.rpc(id) # let the clients know about this new player
		
		for pid in players: # let the new player know about everyone except himself
			if pid != id:
				spawn_player.rpc_id(id, pid)

@rpc("authority", "call_local", "reliable")
func spawn_player(id: int):
	players[id] = {
		"session_id": "", # only known by the server
		"profile_id": "",
		"node": null,
		"init": false
	}

	player_connected.emit(id)

func id():
	return multiplayer.get_unique_id()

func is_server():
	return multiplayer.is_server()
	
@rpc("any_peer", "call_remote", "reliable")
func transfer_ids(user_id: String, session_id: String, profile_id: String):
	if not is_server(): return
	var sender = multiplayer.get_remote_sender_id()
	players[sender]["session_id"] = session_id
	players[sender]["profile_id"] = profile_id
	players[sender]["init"] = true
	
	var resp = await (Networking.http
		.http_get("/profile/" + user_id + "/" + profile_id)
		.send())
	
	if resp.status() != 200:
		return
		
	var profile = (await resp.json())["data"]
	init_player.rpc(sender, Class.from_str(profile["class"]), profile["name"], profile["health"])
	
@rpc("authority", "call_local", "reliable")
func init_player(id: int, pclass: Class.Class, pname: String, health: int):
	var n = players[id].node
	
	n.pclass = pclass
	n.pname = pname
	n.health = health
	n.get_node("Name").text = pname

@rpc("any_peer", "call_remote", "unreliable")
func player_pos(x: float, y: float):
	var sender = multiplayer.get_remote_sender_id()
	players[multiplayer.get_remote_sender_id()]["node"].global_position = Vector2(x, y)
