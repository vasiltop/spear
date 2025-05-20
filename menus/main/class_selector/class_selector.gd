extends HBoxContainer

@onready var select_btn: Button = $Select
@onready var delete_btn: Button = $Delete

var id: String
var char_class: String
var char_name: String

func _ready() -> void:
	delete_btn.pressed.connect(delete)
	select_btn.pressed.connect(func(): Networking.profile_id = id)

func _process(delta: float) -> void:
	select_btn.text = "%s: %s" % [char_class, char_name]

func delete():
	var resp = await (Networking.http
		.http_delete("/class/" + id)
		.header("session-id", Networking.session_id)
		.send())
	
	if resp.status() != 204: return
	
	queue_free()
