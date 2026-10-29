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
@export var slot := ""
@export var display_name := ""
@export var animation := ""
@export var kind := ""
@export var command := "neutral"
@export var description := ""
@export var armor_time := 0.0
@export var invulnerable_time := 0.0
@export var empower_time := 0.0
@export var heal := 0
@export var launch := 0.0
@export var dash_speed := 0.0
@export var escape_stun := false

func duration() -> float:
	return startup + active + recovery
