extends KinematicBody

class_name Player
func get_class(): return "Player"

# exports
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

# movement
var velocity: Vector3
var y_velocity: float
var mouse_turning: bool = false
var mouse_looking: = false
var target_selection_idx: int = 0
var is_moving: bool = false
var is_jumping: bool = false

# selection
var just_selected: bool = false
var target: Target = null setget setTarget
var cast_target: Target = null

# status
var maxHP = 100
onready var hp = maxHP
var maxEnergy = 100
onready var energy = maxEnergy
var buff_list: Array = []

# actions
var auto_attack_cooldown: float = 2
var current_auto_attack_cooldown: float = 0
var attacking: bool = false
var casting: bool = false
var current_cast: Skill = null
var cast_timer: float = 0
onready var heal_spell: Skill = load("res://Resources/Skills/heal.tres")
onready var damage_spell: Skill = load("res://Resources/Skills/damage.tres")
onready var hot: Buff = load("res://Resources/Buffs/hot.tres")

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
	handle_resource_regen(delta)
	handle_effects(delta)
	
	handle_action()
	handle_cast(delta)
	if not casting:
		handle_auto_attack(delta)

func _physics_process(delta):
	handle_movement(delta)
	animation_handler.handle_animation(self)
	
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
		interrupt_cast()
		get_groups()
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
		interrupt_cast()
		is_jumping = true
		y_velocity = jump_power
		
	velocity.y = y_velocity
	
	velocity = move_and_slide(velocity, Vector3.UP)

func handle_action():
	if Input.is_action_just_pressed("select_next"):
		var a = get_tree().get_nodes_in_group("targetable")
		if len(a) > 0:
			if target_selection_idx >= len(a):
				target_selection_idx = 0 
				
			setTarget(a[target_selection_idx])
			target.select()
			target_selection_idx+=1
	
	if Input.is_action_just_pressed("ui_cancel"):
		attacking = false
		interrupt_cast()
		
		animation_handler.cancelAttackAnimation()
		if target != null:
			target.unselect()
			target = null
			
		hud.find_node("Slot1", true).texture = null
	
	if !casting:
		if Input.is_action_just_pressed("hk_2"):
			start_cast(heal_spell)
			
		if Input.is_action_just_pressed("hk_4"):
			start_cast(damage_spell)
			
			
		if not target == null:
			if Input.is_action_just_pressed("hk_1"):
				hud.find_node("Slot1", true).texture = load("res://GUI/HUD/ActiveFrame.png")
				attacking = true
				
			if Input.is_action_just_pressed("hk_3") and target.get_class() == "Enemy":
				target.setTarget(self)
			
func handle_auto_attack(delta):
	if not target == null and attacking:
		auto_attack(delta)

func handle_resource_regen(delta):
	energy = clamp(energy + delta * 2, 0, maxEnergy)
	energy_bar.value = energy

func handle_hit(dmg, dmg_type):
	if dmg_type == "none":
		return
	hp = clamp(hp - dmg, 0, maxHP)
	hp_bar.value = hp

func handle_effects(delta):
	if len(buff_list) == 0:
		return
	
	for i in len(buff_list):
		var buff = buff_list[i]
		buff[1] += delta
		if buff[0].duration <= buff[1]:
			buff_list.remove(i)
			print("Removed Buff ", buff[0].name)
			return
			
	
###############################
########## Targeting ##########
###############################

func _handle_taget_died(reference):
	if reference == target:
		attacking = false
		animation_handler.cancelAttackAnimation()
		target = null
		hud.find_node("Slot1", true).texture = null
		
	if reference == cast_target:
		interrupt_cast()
		
func setTarget(selection):
	if selection == target:
		return
	just_selected = true
	if target != null:
		target.unselect()
		target.disconnect("enemy_died", self, "_handle_taget_died")
		
	target = selection
	if not target.is_connected("enemy_died", self, "_handle_taget_died"):
		target.connect("enemy_died", self, "_handle_taget_died")

###############################
########## CASTING ############
###############################

func auto_attack(delta):
	current_auto_attack_cooldown += delta
	if current_auto_attack_cooldown > auto_attack_cooldown:
		if(translation - target.translation).length() < meele_range:
			animation_handler.playAttackAnimaiton("Hexblade_Base-loop")
			target.handle_hit(25, "physical", self)
			current_auto_attack_cooldown = 0
		else:
			animation_handler.cancelAttackAnimation()
			current_auto_attack_cooldown = 0
			hud.display_message("Out of Range")

func start_cast(spell: Skill):
	if energy < spell.mana_cost:
		hud.display_message("Not Enough Mana")
		return
		
	if spell.hostile:
		if target == null:
			hud.display_message("No Target")
			return
		cast_target = target
	
	energy -= spell.mana_cost
	energy_bar.value = energy
	cast_bar.show()
	cast_timer = 0
	current_cast= spell
	casting = true
	
func finish_cast():
	cast_bar.hide()
	cast_timer = 0
	casting = false
	
	if current_cast.hostile == true:
		cast_target.handle_hit(current_cast.base_damage, "magical", self)
		cast_target == null
	else:
		hp = clamp(hp + current_cast.base_damage , 0, maxHP)
		hp_bar.value = hp
		buff_list.append([hot, 0])
	
func interrupt_cast():
	cast_bar.hide()
	cast_timer = 0
	casting = false
	
func handle_cast(delta):
	if !casting:
		return
	
	cast_timer += delta
	cast_bar.value = (cast_timer / current_cast.cast_time) * 100
	if cast_timer >= current_cast.cast_time:
		finish_cast()

	
