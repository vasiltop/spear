class_name Map extends Node

@onready var spawns: Node = $Spawns

var _spawn_counter: int

func get_spawns() -> Array[Node2D]:
	return spawns.get_children() as Array[Node2D]

func get_next_spawn() -> Vector2:
	var node := spawns.get_child(_spawn_counter) as Node2D
	var pos := node.global_position
	
	_spawn_counter += 1
	
	if _spawn_counter >= spawns.get_child_count():
		_spawn_counter = 0
	
	return pos
