class_name Weapon extends Resource

enum WeaponType {
	PROJECTILE,
	GUN,	
}

@export var name: String
@export var damage: int
@export var type: WeaponType
@export var texture: Texture2D

func _init(name := "Weapon", damage := 100, type := WeaponType.PROJECTILE, texture: Texture2D = null) -> void:
	self.name = name
	self.damage = damage
	self.type = type
	self.texture = texture
