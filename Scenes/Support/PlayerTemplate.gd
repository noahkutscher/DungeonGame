extends KinematicBody

onready var animation_handler = $Hexblade

var casting = false
var attacking = false
var is_moving = false
var is_jumping = false

func _physics_process(delta):
	animation_handler.handle_animation(self)

func MovePlayer(pos, rot):
	translation = pos
	rotation = rot
	

