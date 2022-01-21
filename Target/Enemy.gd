extends Target

class_name Enemy
func get_class(): return "Enemy"


# handle movement in here
onready var view = $FOV
var target: Player = null

var velocity: Vector3
var direction: Vector3
var meele_range: float = 2

export var speed: float = 5
export var acceleration: float = 10
export var gravity: float = 0.98
export var max_terminl_velocity: float = 54

var auto_attack_cooldown: float = 2
var current_auto_attach_cooldown: float = 0

func _physics_process(delta):
	handleAttack(delta)
	handle_movement(delta)

func handle_movement(delta):
	if target == null:
		return
		
	direction = target.translation - translation
	look_at(target.translation, Vector3.UP)
	if direction.length() < meele_range:
		return
	
	direction = direction.normalized()
	
	var accel = acceleration
	
	velocity = velocity.linear_interpolate(direction * speed, accel * delta)
		
	velocity = move_and_slide(velocity, Vector3.UP)

func auto_attack(delta):
	current_auto_attach_cooldown += delta
	if current_auto_attach_cooldown > auto_attack_cooldown:
		if(translation - target.translation).length() < meele_range:
			target.handle_hit(5, "physical")
			current_auto_attach_cooldown = 0
		else:
			current_auto_attach_cooldown = 0
			print("Enemy Attack: Out of range")

func handleAttack(delta):
	if target != null:
		auto_attack(delta)
	
func setTarget(player: Player):
	target = player

func _on_FOV_body_entered(body):
	if body.get_class() == "Player":
		print("Target Aquired")
		target = body
		
	
func _on_FOV_body_exited(body):
	pass
