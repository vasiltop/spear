extends VSplitContainer

@onready var message_input: LineEdit = $Message
@onready var messages_container: VBoxContainer = $ScrollContainer/Messages

#	{
#		"name":
#		"message":
#	}

func _ready() -> void:
	Networking.on_chat.connect(on_chat)
	
func on_chat(pid: int, message: String):
	var pname = Networking.player_name(pid)
	var label = Label.new()
	label.text = "%s: %s" % [pname, message]
	messages_container.add_child(label)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("chat"):
		if is_chatting():
			message_input.release_focus()
		else:
			message_input.grab_focus()
			
	if Input.is_action_just_pressed("chat_send") and is_chatting():
		send(message_input.text)
		message_input.clear()
		message_input.release_focus()

func send(message: String):
	Networking.chat.rpc(message)

func is_chatting() -> bool:
	return message_input.has_focus()
