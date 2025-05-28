class_name Map extends Node

@onready var spawns: Node = $Spawns

func get_spawns() -> Array[Node2D]:
	return spawns.get_children() as Array[Node2D]
