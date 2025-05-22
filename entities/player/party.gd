extends HSplitContainer

const UI_PLAYER = preload("res://entities/player/ui/ui_player.tscn")

@onready var all_players_container: GridContainer = $AllPlayers/Players

func _process(delta: float) -> void:
	if all_players_container.get_child_count() != Networking.players.size() - 1:
		print(all_players_container.get_child_count(), Networking.players.size())
		reset()
		
func reset():
	print("reset")
	for n in all_players_container.get_children():
		n.queue_free()
	
	for id in Networking.players:
		if id != Networking.id():
			var inst = UI_PLAYER.instantiate()
			all_players_container.add_child(inst)
			inst.id = id
