extends HBoxContainer

var id: int = 0

@onready var name_label: Label = $Name
@onready var invite: Button = $Invite
@onready var kick: Button = $Kick

func _ready() -> void:
	invite.pressed.connect(func(): Networking.invite.rpc_id(id))
	invite.visible = not Networking.my_party().has(id)
	kick.visible = not invite.visible
	
	if id == Networking.id():
		invite.visible = false
		kick.visible = false

func _process(delta: float) -> void:
	if id == 0: return
	name_label.text = Networking.players[id].node.pname
