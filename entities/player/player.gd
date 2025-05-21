extends CharacterBody2D

@onready var pos_timer: Timer = $PosTimer
@export var speed: float = 30.0

var id: int = -1
var health: float = 0.0
var pclass: Class.Class = Class.Class.WARRIOR
var pname: String = "Player Name"

func _ready() -> void:
	set_physics_process(is_self())
	set_process(is_self())
	
	if not is_self(): return
	
	pos_timer.timeout.connect(
		func():
			Networking.player_pos.rpc(global_position.x, global_position.y)
			pos_timer.start(pos_timer.wait_time)
	)
	pos_timer.start(pos_timer.wait_time)

func is_self() -> bool:
	return Networking.id() == id

func _physics_process(delta: float) -> void:
		var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		if direction.length() > 0:
				direction = direction.normalized()

		velocity = direction * speed
		move_and_slide()
