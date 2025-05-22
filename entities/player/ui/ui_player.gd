extends HBoxContainer

var id: int = 0
@onready var name_label: Label = $Name

func _process(delta: float) -> void:
	if id == 0: return
	
	#print(Networking.players[id].node.pname)
	name_label.text = Networking.players[id].node.pname
