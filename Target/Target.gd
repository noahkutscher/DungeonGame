extends KinematicBody

class_name Target

signal enemy_died(reference)
export var exclusive = true
export var selection_action = "ClickL"

export var maxHp: int = 100
onready var hp: int = maxHp


onready var hp_bar = find_node("HealthBar")
onready var hp_bar_display = $HealthBarDisplay

var dead: bool = false

func _ready():
	hp_bar.max_value = maxHp
	hp_bar.value = maxHp
	hp_bar_display.hide()
	self.add_to_group("targetable", true)
	
func die():
	emit_signal("enemy_died", self)
	queue_free()
	

func handle_hit(dmg, dmg_type, source_entity):
	if dmg_type == "none":
		return
	hp -= dmg
	hp_bar.value = hp
	
	if hp <= 0:
		die()

func unselect():
	hp_bar_display.hide()
	
func select():
	hp_bar_display.show()

