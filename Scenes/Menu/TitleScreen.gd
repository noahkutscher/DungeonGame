extends Control

var startup_world = preload("res://Scenes/World.tscn")

func _on_Button_pressed():
	$Menu/Button.disabled = true
	Server.ip = $Menu/IP_Comp/Input_IP.text
	Server.port = int($Menu/Port_Comp/Input_Port.text)
	$FadeIn.show()
	$FadeIn.fade_in()
	
func _on_FadeIn_fade_finisehd():
	var world = startup_world.instance()
	world.name = "World"
	get_parent().add_child(world)
	
	Server.ConnectToServer()
	
	queue_free()
