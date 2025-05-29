class_name Player extends CharacterBody2D

@onready var camera: Camera2D = $Camera
@onready var sprite: Sprite2D = $Sprite
@onready var weapon_sprite: Sprite2D = $Weapon

const SPEED := 4000
const CAM_SPEED := 0.1

var id: int
var _game: Game
var _last_updated_pos: int
var _equipped_weapon: Weapon
var _health: int = 100

func init(game: Game, id: int) -> void:
	self.id = id
	self._game = game
	
	name = str(id)
	set_physics_process(is_self())
	set_process(is_self())
	set_weapon(load("res://src/entities/player/weapons/spear/spear.tres") as Weapon)
	if is_self(): camera.make_current()

func set_game(game: Game) -> void:
	self._game = game

func to_dict() -> Dictionary:
	var w: Variant = null if not _equipped_weapon else _equipped_weapon.to_dict()
	
	return {
		"global_position": global_position,
		"sprite_flip_h": sprite.flip_h,
		"weapon": w,
		"id": id,
		"name": name,
		"health": _health,
	}
	
func from_dict(data: Dictionary) -> void:
	global_position = data.global_position
	sprite.flip_h = data.sprite_flip_h
	_health = data.health
	
	if data.weapon:
		set_weapon(Weapon.from_dict(data.weapon as Dictionary))
	else:
		set_weapon(null)
	
	id = data.id
	name = data.name
	set_physics_process(is_self())
	set_process(is_self())
	if is_self(): camera.make_current()

func set_weapon(weapon: Weapon) -> void:
	_equipped_weapon = weapon
	
	if weapon:
		weapon_sprite.texture = weapon.texture
	else:
		weapon_sprite.texture = null

func is_self() -> bool:
	return multiplayer.get_unique_id() == self.id

func has_weapon() -> bool:
	return _equipped_weapon != null

func _process(_delta: float) -> void:
	if _game.is_freeze_time(): return
	
	if Input.is_action_just_pressed("attack") and _equipped_weapon:
		var dir := global_position.direction_to(get_global_mouse_position())
		_try_attack.rpc_id(1, dir)

@rpc("any_peer", "call_remote", "reliable")
func _try_attack(dir: Vector2) -> void:
	if not multiplayer.is_server(): return
	var id := Networking.next_object_id()
	_attack.rpc(multiplayer.get_remote_sender_id(), id, dir)
	
@rpc("authority", "call_local", "reliable")
func _attack(attacker: int, id: int, dir: Vector2) -> void:
	InteractableWeapon.throw(attacker, id, _game, _equipped_weapon, dir, 400, global_position)
	set_weapon(null)

func _physics_process(delta: float) -> void:
	camera.global_position += (global_position - camera.global_position) * CAM_SPEED
	
	if _game.is_freeze_time(): return
	
	var direction: Vector2 = Input.get_vector("left", "right", "up", "down").normalized()
	velocity = direction * SPEED * delta
	move_and_slide()
	_try_player_pos.rpc_id(1, global_position)
	
	var sprite_flip_h: bool = sign(global_position.x - get_global_mouse_position().x) > 0
	if sprite_flip_h != sprite.flip_h : _set_sprite_flip_h.rpc(sprite_flip_h)
	_sync_look.rpc(get_global_mouse_position())

@rpc("any_peer", "call_local", "unreliable")
func _sync_look(mouse_pos: Vector2) -> void:
	weapon_sprite.look_at(mouse_pos)

@rpc("any_peer", "call_local", "unreliable")
func _set_sprite_flip_h(val: bool) -> void:
	sprite.flip_h = val
	
@rpc("any_peer", "call_remote", "unreliable")
func _try_player_pos(pos: Vector2) -> void:
	if not multiplayer.is_server(): return
	
	var sender := multiplayer.get_remote_sender_id()
	var current_time := Time.get_ticks_msec()
	var last_sent_time := self._last_updated_pos
	var elapsed := (current_time - last_sent_time) / 1000.0
	
	var old_pos := self.global_position
	
	var max_allowed_distance := SPEED * elapsed * 500
	var distance := pos.distance_to(old_pos)
	self._last_updated_pos = current_time
	
	if distance > max_allowed_distance:
		print("Invalid position packed sent by: %d\n The players speed was %d, covering a distance of %f.\n While his max should be %f." % [sender, SPEED, distance, max_allowed_distance])
		player_pos.rpc_id(sender, old_pos, true)
		return
	
	player_pos.rpc(pos, false)

@rpc("authority", "call_local", "unreliable")
func player_pos(pos: Vector2, fix: bool) -> void:
	if not fix and self.id == multiplayer.get_unique_id(): return
	self.global_position = pos

func damage(amount: int) -> void:
	_health -= amount
	
	if _health <= 0:
		kill.rpc()
		
@rpc("authority", "call_local", "reliable")
func kill() -> void:
	queue_free()
