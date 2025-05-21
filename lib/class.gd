extends Node

enum Class {
	WARRIOR,
	RANGER,
	BERSERKER,
	MUTANT,
	ROGUE
}

func from_str(str: String):
	return Class.get(str.to_upper())
