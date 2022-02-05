extends Control

var startup_world = preload("res://Scenes/World.tscn")
var connecting = false
var wait_time = 10
var waiting = 0

func _ready():
	$ConnectionLost.hide()

func _on_Button_pressed():
	$Menu/Button.disabled = true
	Server.ip = $Menu/IP_Comp/Input_IP.text
	Server.port = int($Menu/Port_Comp/Input_Port.text)
	
	connecting = true
	$FadeIn.show()
	$FadeIn.fade_in()
	
func _on_FadeIn_fade_finisehd():
	Server.ConnectToServer()
	

func _physics_process(delta):
	if connecting:
		waiting += delta
		if waiting >= wait_time:
			$Menu/Button.disabled = false
			connecting = false
			waiting = 0
			$FadeIn.hide()
			trigger_connection_lost_signal()
		
		
	if Server.connected:
		var world = startup_world.instance()
		world.name = "World"
		get_parent().add_child(world)
		queue_free()
			
func trigger_connection_lost_signal():
	$ConnectionLost.show()
