extends HBoxContainer

const UI_PLAYER = preload("res://entities/player/ui/ui_player.tscn")

@onready var player: CharacterBody2D = $"../../.."
@onready var all_players_container: GridContainer = $AllPlayers/Players
@onready var party_container: VBoxContainer = $MyParty/Players

func _ready() -> void:
	if not player.is_self(): return
	
	Networking.players_modified.connect(reset)
	
	reset()
		
func reset():
	for n in all_players_container.get_children():
		n.queue_free()
	
	for n in party_container.get_children():
		n.queue_free()
	
	for id in Networking.players:
		var inst = UI_PLAYER.instantiate()
		inst.id = id
		if id == Networking.id() or Networking.my_party().has(id):
			party_container.add_child(inst)
		else:
			all_players_container.add_child(inst)
