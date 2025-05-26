class_name InteractableWeapon extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite
@onready var area: Area2D = $Area2D

const FRICTION := 0.95

var _weapon: Weapon
var _throw_direction: Vector2
var _game: Game

static func throw(id: int, game: Game, weapon: Weapon, throw_direction: Vector2, vel: int, pos: Vector2) -> void:
	var inst: InteractableWeapon = preload("res://src/entities/player/weapons/InteractableWeapon.tscn").instantiate()
	inst.global_position = pos
	inst._weapon = weapon
	inst.velocity = throw_direction * vel
	inst._throw_direction = throw_direction
	game.add_child(inst)
	inst._game = game
	inst.sprite.texture = weapon.texture
	inst.sprite.look_at(pos + throw_direction)
	inst.name = str(id)

func pickup() -> Weapon:
	self.queue_free()
	return self._weapon

func _physics_process(delta: float) -> void:
	velocity *= FRICTION

	if velocity.length() < 1: velocity = Vector2.ZERO
	move_and_slide()
	
func _process(delta: float) -> void:
	var bodies := area.get_overlapping_bodies()
	
	for body in bodies:
		if body is Player:
			var player := body as Player
			if player.is_self() and Input.is_action_just_pressed("interact"):
				_try_pick_up.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _try_pick_up() -> void:
	var sender := multiplayer.get_remote_sender_id()
	var player := _game.get_player(sender)
	var bodies := area.get_overlapping_bodies()
	
	var valid := false
	
	for body in bodies:
		if body is Player:
			var p := body as Player
			if player.id == sender:
				valid = true
				break
	
	if not valid: return
	_pick_up.rpc(sender)
	
@rpc("authority", "call_local", "reliable")
func _pick_up(id: int) -> void:
	var player := _game.get_player(id)
	player.set_weapon(self._weapon)
	queue_free()
