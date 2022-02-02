extends ColorRect

signal fade_finisehd

onready var anim_player = $AnimationPlayer

func fade_in():
	anim_player.play("fade_in")


func _on_AnimationPlayer_animation_finished(anim_name):
	emit_signal("fade_finisehd")
