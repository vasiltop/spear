extends HBoxContainer

const UI_PLAYER = preload("res://entities/player/ui/ui_player.tscn")

@onready var player: CharacterBody2D = $"../../.."
@onready var all_players_container: GridContainer = $AllPlayers/Players
@onready var party_container: VBoxContainer = $MyParty/Players

func _ready() -> void:
	set_process(player.is_self())
	Networking.party_updated.connect(reset)
	Networking.player_connected.connect(func(id: int): reset())
		
func reset():
	for n in all_players_container.get_children():
		n.queue_free()
	
	for n in party_container.get_children():
		n.queue_free()
	
	for id in Networking.players:
		var inst = UI_PLAYER.instantiate()
		inst.id = id
		print(id in Networking.party)
		if id == Networking.id() or (id in Networking.party):
			party_container.add_child(inst)
		else:
			all_players_container.add_child(inst)
