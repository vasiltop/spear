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
	var inst: Player = PlayerScene.instantiate()
	players.add_child(inst)
	inst.init(self, id)

func get_player(id: int) -> Player:
	for player: Player in players.get_children():
		if player.id == id: return player
		
	return null
