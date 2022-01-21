extends Spatial

onready var animation_player = $AnimationPlayer
var attack_animation: bool = false
var desired_animation = "T-Pose-loop"
var current_attack_animation = ""

func cancelAttackAnimation():
	attack_animation = false
	

func playAttackAnimaiton(name):
	attack_animation = true
	current_attack_animation = name
	animation_player.play(name, -1, 2)
	animation_player.get_animation(animation_player.current_animation).loop = false
	
func handle_animation(player):
	if attack_animation:
		return
		
	if player.is_jumping:
		desired_animation = "Jump-loop"
	elif player.attacking:
		desired_animation = "IdleFight-loop"
	elif player.is_moving:
		desired_animation = "Running-loop"
	else:
		desired_animation = "T-Pose-loop"
	
	var current_anim = animation_player.get_current_animation()
	if desired_animation != current_anim:
		animation_player.play(desired_animation)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == current_attack_animation:
		cancelAttackAnimation()
