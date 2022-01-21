extends KinematicBody

class_name Target

signal enemy_died(reference)
export var exclusive = true
export var selection_action = "ClickL"

export var maxHp: int = 100
onready var hp: int = maxHp


onready var hp_bar = $Viewport/HealthBar
onready var hp_bar_display = $HealthBarDisplay

var dead: bool = false

func _ready():
	hp_bar.max_value = maxHp
	hp_bar.value = maxHp
	hp_bar_display.hide()
	self.add_to_group("targetable", true)
	
func _exit_tree():
	self.remove_from_group("targateble")
	
func die():
	emit_signal("enemy_died", self)
	queue_free()
	

func handle_hit(dmg, dmg_type):
	print("Got Hit for ", dmg, "dmg of type ", dmg_type)
	hp -= dmg
	hp_bar.value = hp
	
	if hp <= 0:
		die()

func unselect():
	hp_bar_display.hide()
	
func select():
	hp_bar_display.show()

func _on_Area_input_event(camera, event, _click_position, _click_normal, _shape_idx):
	if event.is_action_pressed(selection_action):
		select()
		var player = camera.find_parent("Player")
		player.target = self
		
