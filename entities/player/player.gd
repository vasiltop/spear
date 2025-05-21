extends CharacterBody2D

@onready var pos_timer: Timer = $PosTimer

var speed: float = 6500.0
var id: int = -1
var health: float = 0.0
var pclass: Class.Class = Class.Class.WARRIOR
var pname: String = "Player Name"

func _ready() -> void:
	set_physics_process(is_self())
	set_process(is_self())
	
	if not is_self(): return
	
	#pos_timer.timeout.connect(
		#func():
			#Networking.try_player_pos.rpc(global_position.x, global_position.y)
			#pos_timer.start(pos_timer.wait_time)
	#)
	#pos_timer.start(pos_timer.wait_time)

func is_self() -> bool:
	return Networking.id() == id

func _physics_process(delta: float) -> void:
		var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		velocity = direction * speed * delta
		move_and_slide()
		Networking.try_player_pos.rpc_id(0, global_position)
