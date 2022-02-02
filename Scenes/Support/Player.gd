extends KinematicBody

class_name Player
func get_class(): return "Player"

# exports
export var speed: float = 8
export var acceleration: float = 15
export var air_acceleration: float = 5
export var max_terminl_velocity: float = 54
export var jump_power: float = 20
export var turn_speed: float = 240
export var meele_range: float = 2

# movement
var mouse_sensetivity: float = 0.3
var min_pitch: float = -80
var max_pitch: float = 80
var gravity: float = 0.98
var velocity: Vector3
var y_velocity: float
var mouse_turning: bool = false
var mouse_looking: = false
var target_selection_idx: int = 0

# player state
var is_moving: bool = false
var is_jumping: bool = false
var attacking: bool = false
var casting: bool = false

var maxHP = 100
onready var hp = maxHP
var maxEnergy = 100
onready var energy = maxEnergy
var buff_list: Array = []

var player_state

# selection
var just_selected: bool = false
var target: Enemy = null setget setTarget
var cast_target: Enemy = null

# nodes
onready var camera_pivot = $CameraPivot
onready var camera_boom = $CameraPivot/CameraBoom
onready var camera = $CameraPivot/CameraBoom/Camera
onready var animation_handler = $Hexblade
onready var hud = $HUD
onready var hp_bar = $HUD/Health
onready var energy_bar = $HUD/Energy
onready var cast_bar = $HUD/Cast


func _ready():
	hp_bar.max_value = maxHP
	energy_bar.max_value = maxEnergy
	cast_bar.value = 0
	cast_bar.hide()
	
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

func _process(delta):
	handle_action()
	
func _physics_process(delta):
	handle_movement(delta)
	animation_handler.handle_animation(self)
	
	DefinePlayerState()
	
###############################
########## Handler ############
###############################
	
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

func handle_action():
	if Input.is_action_just_pressed("select_next"):
		var a = get_tree().get_nodes_in_group("group_Enemies")
		if len(a) > 0:
			if target_selection_idx >= len(a):
				target_selection_idx = 0 
				
			setTarget(a[target_selection_idx])
			target.select()
			target_selection_idx+=1
	
	if Input.is_action_just_pressed("ui_cancel"):
		attacking = false
		
		animation_handler.cancelAttackAnimation()
		if target != null:
			target.unselect()
			target = null
			
		hud.find_node("Slot1", true).texture = null
	
	if !casting:
		if Input.is_action_just_pressed("hk_2"):
			pass
				
		if not target == null:
			if Input.is_action_just_pressed("hk_4"):
				start_cast(0)
				pass
				
			if Input.is_action_just_pressed("hk_1"):
				hud.find_node("Slot1", true).texture = load("res://GUI/HUD/ActiveFrame.png")
				
			if Input.is_action_just_pressed("hk_3") and target.get_class() == "Enemy":
				pass
			
###############################
########## Targeting ##########
###############################

func setTarget(selection):
	if selection == target:
		return
	if target != null:
		target.unselect()
	target = selection
	just_selected = true
	
func start_cast(spell_id):
	casting = true
	Server.notify_cast_start(int(target.name), spell_id)
	
func finish_cast():
	casting = false

###############################
######## Mulitplayer ##########
###############################
	
func DefinePlayerState():
	player_state = {"T": Server.client_clock, "P": translation, "R": rotation, "M": is_moving, "J": is_jumping, "C": casting}
	Server.SendPlayerState(player_state)
