extends VSplitContainer

const INVITE_CHAT = preload("res://entities/player/ui/invite_chat.tscn")

@onready var message_input: LineEdit = $Message
@onready var messages_container: VBoxContainer = $ScrollContainer/Messages

func _ready() -> void:
	Networking.on_chat.connect(on_chat)
	Networking.invite_from.connect(invite_from)
	
func invite_from(pid: int):
	var inst = INVITE_CHAT.instantiate()
	messages_container.add_child(inst)
	inst.get_node("Message").text = "SYSTEM: Invite from %s" % Networking.player_name(pid)
	inst.get_node("Button").pressed.connect(func(): Networking.try_accept_invite.rpc_id(1, pid))
	
func on_chat(pid: int, message: String):
	var pname = Networking.player_name(pid)
	var label = Label.new()
	label.text = "%s: %s" % [pname, message]
	messages_container.add_child(label)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("chat"):
		if not is_chatting():
			message_input.grab_focus()
			
	if Input.is_action_just_pressed("chat_send") and is_chatting():
		if message_input.text == "start":
			Networking.queue_party.rpc_id(1)
		else:
			if message_input.text != "":
				send(message_input.text)
				message_input.clear()
			message_input.release_focus()

func send(message: String):
	Networking.chat.rpc(message)

func is_chatting() -> bool:
	return message_input.has_focus()
