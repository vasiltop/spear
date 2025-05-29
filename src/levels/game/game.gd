class_name Game extends Node2D

const PlayerScene = preload("res://src/entities/player/player.tscn")
const FREEZE_TIME_DURATION := 2
const END_TIME_DURATION := 3
const MAX_KILLFEED_SIZE := 10
const _maps := [
	"map1",
]

@onready var _status_message: Label = $UI/Content/StatusMessage
@onready var killfeed: VBoxContainer = $UI/Content/Killfeed

var _freeze_timer: float
var _is_freeze_time := true
var _current_map: Map
var _waiting_for_players: bool = true
var _end_timer: float
var _current_spec_player_index: int

func _ready() -> void:
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	
	if multiplayer.is_server():
		load_map.rpc(_maps[0])

@rpc("authority", "call_local", "reliable")
func _show_status_message(message: String) -> void:
	_status_message.text = message
	_status_message.show()

@rpc("authority", "call_local", "reliable")
func _hide_status_message() -> void:
	_status_message.hide()

@rpc("authority", "call_local", "reliable")
func load_map(map_name: String) -> void:
	var inst := load("res://src/levels/%s/%s.tscn" % [map_name, map_name]) as PackedScene
	var map := inst.instantiate() as Map
	map.name = map_name
	add_child(map)
	
	if _current_map:
		_current_map.queue_free()
		
	_current_map = map

func _peer_disconnected(id: int) -> void:
	get_player(id).queue_free()

func _change_spec(value: int) -> void:
	var temp := _current_spec_player_index + value
	var max_index := _get_players().size() - 1

	if temp > max_index: _current_spec_player_index = 0
	elif temp < 0: _current_spec_player_index = max_index
	else: _current_spec_player_index = temp

func _process(delta: float) -> void:
	if not im_alive() and _get_players().size() and not multiplayer.is_server():

		if _current_spec_player_index >= _get_players().size() or _current_spec_player_index < 0:
			_change_spec(1)
		
		_get_players()[_current_spec_player_index].camera.make_current()
		
		if Input.is_action_just_pressed("spec_next"):
			_change_spec(1)
		elif Input.is_action_just_pressed("spec_prev"):
			_change_spec(-1)

	if not multiplayer.is_server(): return
	var player_count := multiplayer.get_peers().size()

	if player_count < 2 and not _waiting_for_players:
		_waiting_for_players = true
		load_map.rpc(_maps[0])
	elif player_count >= 2:
		_waiting_for_players = false

		if _is_freeze_time:
			_show_status_message.rpc("Get Ready..")
			_freeze_timer += delta
			if _freeze_timer >= FREEZE_TIME_DURATION:
				_update_freeze_time.rpc(false)
				_freeze_timer = 0
		else:
			_hide_status_message.rpc()
			
		if _player_alive_count() <= 1 and _end_timer >= END_TIME_DURATION:
			# reset the game since the extra margin time ran out
			_end_timer = 0
			_update_freeze_time.rpc(true)
			_destroy_all_persistent.rpc()
			_show_status_message.rpc("Get Ready..")
			_clear_killfeed.rpc()
			
			for id in multiplayer.get_peers():
				_spawn_player(id)
				
		elif _player_alive_count() <= 1:
			_end_timer += delta
			
			if _player_alive_count() == 1:
				var player_name := _get_players()[0].name
				_show_status_message.rpc("Player: " + player_name + " has won the round!")

@rpc("authority", "call_local", "reliable")
func _kill_all_players() -> void:
	for player in _get_players():
		player.queue_free()

@rpc("authority", "call_local", "reliable")
func _destroy_all_persistent() -> void:
	for node in get_tree().get_nodes_in_group("persistent"):
		node.queue_free()

func _player_alive_count() -> int:
	var count := 0
	
	for player in _get_players():
		if not player.dead: count += 1
		
	return count

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
		
	load_map.rpc_id(id, _current_map.name)

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

@rpc("authority", "call_local", "reliable")
func add_to_killfeed(id_killed: int, id_killer: int, weapon_name: String) -> void:
	if killfeed.get_child_count() >= MAX_KILLFEED_SIZE:
		killfeed.get_child(0).queue_free()
		
	var label := Label.new()
	label.text = "%d was killed by %d using a %s" % [id_killed, id_killer, weapon_name]
	label.add_theme_font_size_override("font_size", 21)
	killfeed.add_child(label)

@rpc("authority", "call_local", "reliable")
func _clear_killfeed() -> void:
	for node in killfeed.get_children():
		node.queue_free()

func im_alive() -> bool:
	var my_player := get_player(multiplayer.get_unique_id())
	if my_player == null: return false
	
	return my_player.dead == false
