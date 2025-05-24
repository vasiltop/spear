extends HBoxContainer

var id: int = 0

@onready var name_label: Label = $Name
@onready var invite: Button = $Invite
@onready var kick: Button = $Kick
@onready var leave: Button = $Leave

func _ready() -> void:
	invite.pressed.connect(func(): Networking.invite.rpc_id(id))
	kick.pressed.connect(func(): Networking.kick.rpc_id(0, id))
	leave.pressed.connect(func(): Networking.leave.rpc_id(0))
	
	invite.visible = not Networking.my_party().has(id)
	kick.visible = (not invite.visible) and Networking.im_party_leader()
	leave.visible = false
	
	if id == Networking.id():
		invite.visible = false
		kick.visible = false
		
		if Networking.my_party().size() > 1:
			leave.visible = true

func _process(delta: float) -> void:
	if id == 0: return
	name_label.text = Networking.players[id].node.pname
