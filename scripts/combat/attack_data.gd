class_name AttackData
extends Resource
@export var id: String
@export var damage: int
@export var startup: float
@export var active: float
@export var recovery: float
@export var reach: float
@export var knockback: float
@export var hitstun: float
@export var meter_gain: int
@export var cooldown: float = 0.0
@export var meter_cost: int = 0

func duration() -> float:
	return startup + active + recovery
