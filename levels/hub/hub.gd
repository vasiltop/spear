extends Node2D

const PLAYER = preload("res://entities/player/player.tscn")

@onready var players: Node = $Players
@onready var spawn_point: Node2D = $SpawnPoint

func _ready() -> void:
	Networking.player_connected.connect(spawn_player)
	
func spawn_player(id: int):
	var t = Networking.id()
	var p = PLAYER.instantiate()
	Networking.players[id]["node"] = p
	p.id = id
	p.global_position = spawn_point.global_position
	players.add_child(p)
