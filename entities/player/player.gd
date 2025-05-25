extends CharacterBody2D

@onready var ui: CanvasLayer = $UI
@onready var tab_bar: TabContainer = $UI/TabBar
@onready var chat: VSplitContainer = $UI/Chat
@onready var camera: Camera2D = $Camera

@export var speed: float
@export var cam_speed: float

var id: int = -1
var health: float = 0.0
var pclass: Class.Class = Class.Class.WARRIOR
var pname: String = "Player Name"

func _ready() -> void:
	set_physics_process(is_self())
	set_process(is_self())
	ui.visible = is_self()
	camera.enabled = is_self()
	
	if is_self():
		camera.make_current()
	
	tab_bar.visible = false

func is_self() -> bool:
	return Networking.id() == id

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_ui"):
		tab_bar.visible = !tab_bar.visible
		
func _physics_process(delta: float) -> void:
		if chat.is_chatting(): return
		
		var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		velocity = direction * speed * delta
		move_and_slide()
		Networking.try_player_pos.rpc_id(1, global_position)
		
		camera.global_position += (global_position - camera.global_position) * cam_speed
