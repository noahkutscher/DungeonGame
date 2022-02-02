extends Control


func _on_Button_pressed():
	$FadeIn.show()
	$FadeIn.fade_in()

func _on_FadeIn_fade_finisehd():
	Server.ConnectToServer()
	get_tree().change_scene("res://Scenes/World.tscn")
