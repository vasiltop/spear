extends HBoxContainer

var id: int = 0

@onready var name_label: Label = $Name
@onready var invite: Button = $Invite
@onready var kick: Button = $Kick

func _ready() -> void:
	invite.pressed.connect(func(): Networking.invite.rpc_id(id))

func _process(delta: float) -> void:
	if id == 0: return
	name_label.text = Networking.players[id].node.pname
