class_name Game extends Node2D

const PlayerScene = preload("res://src/entities/player/player.tscn")
const FREEZE_TIME_DURATION := 2
const _maps := [
	"res://src/levels/test/test.tscn",
]

var _freeze_timer: float
var _is_freeze_time := true
var _current_map: Map
var _waiting_for_players: bool = true

func _ready() -> void:
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	
	if multiplayer.is_server():
		load_map.rpc(_maps[0])

@rpc("authority", "call_local", "reliable")
func load_map(path: String) -> void:
	var inst := load(path) as PackedScene
	var map := inst.instantiate() as Map
	add_child(map)
	
	if _current_map:
		_current_map.queue_free()
		
	_current_map = map

func _peer_disconnected(id: int) -> void:
	get_player(id).queue_free()

func _process(delta: float) -> void:
	if not multiplayer.is_server(): return
	var player_count := multiplayer.get_peers().size()

	if player_count < 2 and not _waiting_for_players:
		_waiting_for_players = true
		load_map.rpc(_maps[0])
	elif player_count >= 2:
		_waiting_for_players = false
		
		if _is_freeze_time:
			_freeze_timer += delta
			if _freeze_timer >= FREEZE_TIME_DURATION:
				_update_freeze_time.rpc(false)
				_freeze_timer = 0
		
		if _player_alive_count() <= 1:
			_update_freeze_time.rpc(true)
			_destroy_all_persistent.rpc()
			
			for id in multiplayer.get_peers():
				_spawn_player(id)

@rpc("authority", "call_local", "reliable")
func _kill_all_players() -> void:
	for player in _get_players():
		player.queue_free()

@rpc("authority", "call_local", "reliable")
func _destroy_all_persistent() -> void:
	for node in get_tree().get_nodes_in_group("persistent"):
		node.queue_free()

func _player_alive_count() -> int:
	return _get_players().size()

func _get_players() -> Array[Player]:
	var res: Array[Player] = []
	
	for node in get_children():
		if node is Player:
			res.append(node as Player)
			
	return res

@rpc("authority", "call_local", "reliable")
func _update_freeze_time(value: bool) -> void:
	self._is_freeze_time = value

func is_freeze_time() -> bool:
	return _is_freeze_time

func _spawn_player(id: int) -> Player:
	var inst: Player = PlayerScene.instantiate()
	add_child(inst)
	inst.init(self, id)
	inst.global_position = _current_map.get_next_spawn()
	
	for peer_id in multiplayer.get_peers():
		_init_node.rpc_id(peer_id, inst.scene_file_path, inst.call("to_dict"))
	
	return inst

func _peer_connected(id: int) -> void:
	if not multiplayer.is_server(): return
	
	if is_freeze_time():
		_spawn_player(id)

	for node in get_tree().get_nodes_in_group("persistent"):
		if node.has_method("to_dict"):
			if node is Player:
				var player := node as Player
				if player.id == id: continue
			_init_node.rpc_id(id, node.scene_file_path, node.call("to_dict"))
		
	load_map.rpc_id(id, _current_map.scene_file_path)

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
