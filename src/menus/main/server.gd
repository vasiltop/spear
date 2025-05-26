class_name Server extends HBoxContainer

@onready var label: Label = $Label
@onready var button: Button = $Button

var _ip: String
var _port: int

func _ready() -> void:
	button.pressed.connect(
		func() -> void:
			Networking.create_client(self._ip, self._port)
	)

func init(ip: String, port: int, sname: String) -> void:
	self._ip = ip
	self._port = port
	
	label.text = sname
