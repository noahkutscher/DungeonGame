extends KinematicBody

class_name Enemy
func get_class(): return "Enemy"

export var MaxHealth = 100
onready var Health = MaxHealth

onready var hp_bar = $Viewport/HealthBar
onready var hp_bar_display = $HealthBarDisplay
onready var mouseSelectionArea = $MouseSelectionArea

var dead: bool = false

func _ready():
	add_to_group("group_Enemies")
	hp_bar.max_value = MaxHealth
	hp_bar.value = Health
	
	mouseSelectionArea.connect("input_event", self, "on_selection_input_event")
	unselect()
	
func on_selection_input_event(camera, event, click_position, click_normal, shape_idx):
	if Input.is_action_just_pressed("ClickL"):
		self.select()
		camera.find_parent("Player").setTarget(self)

func MoveEnemy(newPosition):
	translation = newPosition

func setMaxHealth(val):
	MaxHealth = val
	hp_bar.max_value = MaxHealth
	
func setHealth(val):
	Health = val
	hp_bar.value = Health
	
func unselect():
	hp_bar_display.hide()
	
func select():
	hp_bar_display.show()
