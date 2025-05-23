extends Node

signal player_connected(pid: int)
signal on_chat(pid: int, message: String)
signal invite_from(pid: int)
signal party_updated()

const API_URL: String = "http://localhost:3000"
const SESSION_ID_FILE: String = "user://session.dat"

@onready var http: BetterHTTPClient = BetterHTTPClient.new(self, BetterHTTPURL.parse(API_URL))

var session_id: String = ""
var user_id: String = ""
var profile_id = null
var current_party_id_counter = 0

var players = {
# example:
#	-1: {
#		"session_id": "",
#		"profile_id": "",
#		"node": null,
#		"init": false,
#		"last_updated_pos": 0
#   "party_id": 0
#	}
}

var party = []

func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	
func peer_connected(id: int):
	print(id(), ": Connected to peer ", id)
	
	if is_server():
		spawn_player.rpc(id) # let the clients know about this new player
		
		for pid in players: # let the new player know about everyone except himself
			if pid != id:
				spawn_player.rpc_id(id, pid)
				if players[pid]["init"]:
					var n = players[pid]["node"]
					init_player.rpc_id(id, pid, n.pclass, n.pname, n.health)

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
func try_player_pos(pos: Vector2):
	if not is_server(): return
	
	var sender = multiplayer.get_remote_sender_id()
	var current_time = Time.get_ticks_msec()
	var last_sent_time = players[sender].last_updated_pos
	
	var elapsed = (current_time - last_sent_time) / 1000.0 # convert to seconds
	
	var old_pos = players[sender].node.global_position
	var spd = players[sender].node.speed
	
	var max_allowed_distance = spd * elapsed / 60.0 * 2
	var distance = pos.distance_to(old_pos)

	players[sender].last_updated_pos = current_time
	
	if distance > max_allowed_distance:
		print("Invalid position packed sent by: %d\n The players speed was %d, covering a distance of %f.\n While his max should be %f." % [sender, spd, distance, max_allowed_distance])
		player_pos.rpc(sender, old_pos, true)
		return
	
	player_pos.rpc(sender, pos, false)

@rpc("authority", "call_local", "unreliable")
func player_pos(id: int, pos: Vector2, fix: bool):
	if id == id() and not fix: return
	players[id]["node"].global_position = pos

@rpc("authority", "call_local", "reliable")
func spawn_player(id: int):
	players[id] = {
		"session_id": "", # only known by the server
		"profile_id": "",
		"node": null,
		"init": false,
		"last_updated_pos": Time.get_ticks_msec(),
		"party_id": next_party_id()
	}

	player_connected.emit(id)

@rpc("any_peer", "call_local", "reliable")
func chat(message: String):
	var pid = multiplayer.get_remote_sender_id()
	on_chat.emit(pid, message)

@rpc("any_peer", "call_remote", "reliable")
func invite():
	var pid = multiplayer.get_remote_sender_id()
	invite_from.emit(pid)

@rpc("any_peer", "call_remote", "reliable")
func accept_invite(pid: int):
	if not is_server(): return
	
	var sender = multiplayer.get_remote_sender_id()
	var party_id = player_party(pid)
	
	if get_party_size(party_id) >= 3:
		print("Invalid invite, party size was too large: %d" % get_party_size(party_id))
		return

	players[sender].party_id = party_id
	print("%d accepted invite from %d" % [pid, sender])
	
	var p = get_party(party_id)
	for id in p:
		update_party.rpc_id(id, p)
	
@rpc("authority", "call_remote", "reliable")
func update_party(players: Array[int]) -> void:
	party = players
	party_updated.emit()
	print("received party update")

func player_name(pid: int):
	return players[pid].node.pname

func next_party_id() -> int:
	current_party_id_counter += 1
	return current_party_id_counter

func get_party(party_id: int) -> Array[int]:
	var res: Array[int] = []
	
	for pid in players:
		if players[pid].party_id == party_id:
			res.append(pid)
			
	return res

func get_party_size(party_id: int) -> int:
	return get_party(party_id).size()
	
func player_party(pid: int) -> int:
	return players[pid].party_id
