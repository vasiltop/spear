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

func to_dict() -> Dictionary:
	return {
		"name": self.name,
		"damage": self.damage,
		"type": self.type,
		"texture_path": self.texture.resource_path
	}
	
static func from_dict(data: Dictionary) -> Weapon:
	return Weapon.new(data.name as String, data.damage as int, data.type as WeaponType, load(data.texture_path as String) as Texture2D)
