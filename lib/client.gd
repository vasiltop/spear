extends Node

func _ready() -> void:
	Networking.multiplayer.connected_to_server.connect(connected_to_server)

func connected_to_server():
	Networking.transfer_session_id.rpc_id(1, Networking.session_id)
	Networking.spawn_player(Networking.id())
	
func connect_to_server(ip, port):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	Networking.multiplayer.multiplayer_peer = peer
