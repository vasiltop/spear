extends CharacterBody2D

@export var speed: float = 30.0
var id: int = -1

func _ready() -> void:
	set_physics_process(is_self())
	set_process(is_self())

func is_self() -> bool:
	return Networking.id() == id

func _physics_process(delta: float) -> void:
		var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		if direction.length() > 0:
				direction = direction.normalized()

		velocity = direction * speed
		move_and_slide()
