extends Control

class_name Hud

var timer: float = 0

onready var MessageBox = $MessageBox

func _ready():
	MessageBox.hide()
	
func _process(delta):
	if timer == 0:
		return
		
	timer -= delta
	if timer <= 0:
		timer = 0
		MessageBox.hide()

func display_message(message: String):
	MessageBox.bbcode_text = "[center]" + message + "[/center]"
	MessageBox.show()
	timer = 1
	

