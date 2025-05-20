extends HBoxContainer

signal deleted(id: String)
signal selected(id: String)

@onready var select_btn: Button = $Select
@onready var delete_btn: Button = $Delete

var id: String
var char_class: String
var char_name: String
var is_selected: bool = false

func _ready() -> void:
	delete_btn.pressed.connect(delete)
	select_btn.pressed.connect(on_selected)

func on_selected():
	Networking.profile_id = id
	selected.emit(id)

func _process(delta: float) -> void:
	select_btn.text = "%s: %s\n%s" % [char_class, char_name, "Selected" if is_selected else ""]

func delete():
	var resp = await (Networking.http
		.http_delete("/class/" + id)
		.header("session-id", Networking.session_id)
		.send())
	
	if resp.status() != 204: return
	
	deleted.emit(id)
	queue_free()
