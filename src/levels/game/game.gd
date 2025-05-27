class_name Game extends Node2D

@onready var players: Node = $Players

const PlayerScene = preload("res://src/entities/player/player.tscn")

func _ready() -> void:
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	if !multiplayer.is_server(): _peer_connected(multiplayer.get_unique_id())

func _peer_disconnected(id: int) -> void:
	get_player(id).queue_free()

func _peer_connected(id: int) -> void:
	if not multiplayer.is_server(): return
	
	var inst: Player = PlayerScene.instantiate()
	add_child(inst)
	inst.init(self, id)

	for node in get_tree().get_nodes_in_group("persistent"):
		if node.has_method("to_dict"):
			_init_node.rpc_id(id, node.scene_file_path, node.call("to_dict"))
			
	for peer_id in multiplayer.get_peers():
		if peer_id == id: continue
		_init_node.rpc_id(peer_id, inst.scene_file_path, inst.call("to_dict"))

@rpc("authority", "call_remote", "reliable")
func _init_node(scene_path: String, data: Dictionary) -> void:
	var node := (load(scene_path) as PackedScene).instantiate()
	add_child(node)
	
	if node.has_method("from_dict"):
		node.call("from_dict", data)
		
	if node.has_method("set_game"):
		node.call("set_game", self)

func get_player(id: int) -> Player:
	for node in get_children():
		if node is not Player: continue
		var player: Player = node
		if player.id == id: return player
		
	return null
