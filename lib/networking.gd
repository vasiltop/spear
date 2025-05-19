extends Node

signal player_connected(id: int)

const API_URL: String = "http://localhost:3000"
const SESSION_ID_FILE: String = "user://session.dat"

var session_id: String = ""

var players = {
#	-1: {
#		"session_id": -1,
#		"node": null
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
		"session_id": -1, # only known by the server
		"node": null
	}
	
	player_connected.emit(id)

func id():
	return multiplayer.get_unique_id()

func is_server():
	return multiplayer.is_server()
	
@rpc("any_peer", "call_remote", "reliable")
func transfer_session_id(session_id: String):
	if not is_server(): return
	var sender = multiplayer.get_remote_sender_id()
	players[sender]["session_id"] = session_id
