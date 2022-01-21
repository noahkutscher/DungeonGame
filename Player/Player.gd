extends KinematicBody

class_name Player
func get_class(): return "Player"

export var speed: float = 8
export var acceleration: float = 15
export var air_acceleration: float = 5
export var gravity: float = 0.98
export var max_terminl_velocity: float = 54
export var jump_power: float = 20

export var turn_speed: float = 240
export var meele_range: float = 2

export(float, 0.1, 1) var mouse_sensetivity: float = 0.3
export(float, -90, 0) var min_pitch: float = -80
export(float, 0, 90) var max_pitch: float = 80

var velocity: Vector3
var y_velocity: float

var mouse_turning: bool = false
var mouse_looking: = false
var target_selection_idx: int = 0

var is_moving: bool = false
var is_jumping: bool = false

var just_selected: bool = false

var target: Target = null setget setTarget

var auto_attack_cooldown: float = 2
var current_auto_attach_cooldown: float = 0
var attacking: bool = false

var maxHP = 100
onready var hp = maxHP

onready var camera_pivot = $CameraPivot
onready var camera_boom = $CameraPivot/CameraBoom
onready var camera = $CameraPivot/CameraBoom/Camera
onready var animation_handler = $Hexblade
onready var hud = $HUD
onready var hp_bar = $HUD/Health

func _ready():
	hp_bar.max_value = maxHP
	
	
func _input(event):
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_DOWN:
				camera_boom.spring_length += 0.4
			if event.button_index == BUTTON_WHEEL_UP:
				camera_boom.spring_length -= 0.4
			
		camera_boom.spring_length = clamp(camera_boom.spring_length, 2, 15)
	
	if event is InputEventMouseMotion:		
		if mouse_looking:	
			camera_pivot.rotation_degrees.x -= event.relative.y * mouse_sensetivity
			camera_pivot.rotation_degrees.x = clamp(camera_pivot.rotation_degrees.x, min_pitch, max_pitch)
			camera_pivot.rotation_degrees.y -= event.relative.x * mouse_sensetivity
		
		elif mouse_turning:
			camera_pivot.rotation_degrees.x -= event.relative.y * mouse_sensetivity
			camera_pivot.rotation_degrees.x = clamp(camera_pivot.rotation_degrees.x, min_pitch, max_pitch)
			rotation_degrees.y -= event.relative.x * mouse_sensetivity

func _physics_process(delta):
	handle_action()
	handle_movement(delta)
	animation_handler.handle_animation(self)
	
func handle_movement(delta):
	
	if is_jumping and is_on_floor():
		is_jumping = false
	
	if Input.is_action_just_pressed("ClickR"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		rotation_degrees.y += camera_pivot.rotation_degrees.y
		camera_pivot.rotation_degrees.y = 0
		mouse_turning = true
	
	if Input.is_action_just_released("ClickR"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		mouse_turning = false
		
		
	if Input.is_action_just_pressed("ClickL"):
		if just_selected:
			just_selected = false
		else:
			mouse_looking = true
	
	if Input.is_action_just_released("ClickL"):
		mouse_looking = false
	
	var direction = Vector3()
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_back"):
		direction += transform.basis.z
		
	if mouse_turning:
		if Input.is_action_pressed("move_left"):
			direction -= transform.basis.x
		if Input.is_action_pressed("move_right"):
			direction += transform.basis.x
	else:
		if Input.is_action_pressed("move_left"):
			rotation_degrees.y += turn_speed * delta

		if Input.is_action_pressed("move_right"):
			rotation_degrees.y -= turn_speed * delta

			
	direction = direction.normalized()
	if direction.length() > 0:
		is_moving = true
	else:
		is_moving = false
	
	var accel = acceleration if is_on_floor() else air_acceleration
	
	velocity = velocity.linear_interpolate(direction * speed, accel * delta)
	
	# needed to be surely pinned to the floor
	if is_on_floor():
		y_velocity = -0.01
	else:
		y_velocity = clamp(y_velocity - gravity, -max_terminl_velocity, max_terminl_velocity)
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		is_jumping = true
		y_velocity = jump_power
		
	velocity.y = y_velocity
	
	velocity = move_and_slide(velocity, Vector3.UP)

func _process(delta):
	if not target == null and attacking:
		auto_attack(delta)

func auto_attack(delta):
	current_auto_attach_cooldown += delta
	if current_auto_attach_cooldown > auto_attack_cooldown:
		if(translation - target.translation).length() < meele_range:
			animation_handler.playAttackAnimaiton("Hexblade_Base-loop")
			target.handle_hit(25, "physical")
			current_auto_attach_cooldown = 0
		else:
			animation_handler.cancelAttackAnimation()
			current_auto_attach_cooldown = 0
			print("Out of range")

func handle_action():
	
	if Input.is_action_just_pressed("select_next"):
		var a = get_tree().get_nodes_in_group("targetable")
		if len(a) > 0:
			if target_selection_idx >= len(a):
				target_selection_idx = 0 
				
			setTarget(a[target_selection_idx])
			target.select()
			target_selection_idx+=1
	
	if Input.is_action_just_pressed("hk_2"):
		handle_heal(30)
		
	if Input.is_action_just_pressed("hk_4"):
		handle_hit(10, "physical")
		
		
	if not target == null:
		if Input.is_action_just_pressed("hk_1"):
			hud.find_node("Slot1", true).texture = load("res://GUI/HUD/ActiveFrame.png")
			attacking = true
			
		if Input.is_action_just_pressed("hk_3") and target.get_class() == "Enemy":
			target.setTarget(self)
			
		
		if Input.is_action_just_pressed("ui_cancel"):
			attacking = false
			animation_handler.cancelAttackAnimation()
			target.unselect()
			target = null
			hud.find_node("Slot1", true).texture = null

func _handle_taget_died(reference):
	attacking = false
	animation_handler.cancelAttackAnimation()
	target = null
	hud.find_node("Slot1", true).texture = null
		
	
func setTarget(selection):
	if selection == target:
		return
	just_selected = true
	if target != null:
		target.unselect()
		target.disconnect("enemy_died", self, "_handle_taget_died")
		
	target = selection
	target.connect("enemy_died", self, "_handle_taget_died")
	
func handle_hit(dmg, dmg_type):
	hp = clamp(hp - dmg, 0, maxHP)
	hp_bar.value = hp

func handle_heal(heal):
	hp = clamp(hp + heal, 0, maxHP)
	hp_bar.value = hp
