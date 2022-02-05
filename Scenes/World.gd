extends Spatial

var playerTeplate = preload("res://Scenes/Support/PlayerTemplate.tscn")
var enemyTeplate = preload("res://Target/Target.tscn")
var last_world_state = 0
var world_state_buffer = []
const interpolation_offset = 100

var despawn_queue = []
var disconnect_queue = []

func interpolate_y_rotation(rot_0, rot_1, factor):
	var temp_rot_1 = rot_1.y - 2 * PI * sign(rot_1.y)
	var skip_over = abs(rot_0.y - rot_1.y) > abs(rot_0.y - temp_rot_1)
	if skip_over:
		rot_1.y = temp_rot_1
	return lerp(rot_0, rot_1, factor)
	

func SpawnNewPlayer(player_id, spawn_position):
	if get_tree().get_network_unique_id() == player_id:
		return
	var player = playerTeplate.instance()
	player.translation = spawn_position
	player.name = str(player_id)
	get_node("OtherPlayers").add_child(player)
	print("Spawn")
	
func SpawnNewEnemy(enemy_id, enemy_info):
	print("spawning enemy")
			
	var enemy = enemyTeplate.instance()
	enemy.translation = enemy_info["EnemyLocation"]
	enemy.MaxHealth = enemy_info["EnemyMaxHealth"]
	enemy.Health = enemy_info["EnemyHealth"]
	enemy.name = str(enemy_id)
	get_node("Enemies").add_child(enemy)
	
func DespawnNewPlayer(player_id):
	get_node("OtherPlayers/" + str(player_id)).queue_free()
	disconnect_queue.append(player_id)
	
func DespawnEnemy(enemy_id):
	get_node("Enemies/" + str(enemy_id)).queue_free()
	despawn_queue.append(enemy_id)
	
	
func _physics_process(delta):
	var render_time = Server.client_clock - interpolation_offset
	if world_state_buffer.size() > 1:
		while world_state_buffer.size() > 2 and render_time > world_state_buffer[1].T:
			world_state_buffer.remove(0)
		var interpolation_factor = float(render_time - world_state_buffer[0]["T"]) / float(world_state_buffer[1]["T"] - world_state_buffer[0]["T"])
		
		if len(disconnect_queue) > 0:
			for entry in disconnect_queue:
				if not entry in world_state_buffer[1]["Players"].keys():
					disconnect_queue.erase(entry)
		
		if len(despawn_queue) > 0:
			for entry in despawn_queue:
				if not entry in world_state_buffer[1]["Enemies"].keys():
					despawn_queue.erase(entry)
		
		######### syncing player state
		for player in world_state_buffer[1]["PState"].keys():
			if player == get_tree().get_network_unique_id():
				get_node("Player").setHP(world_state_buffer[1]["PState"][player]["PlayerHealth"])
				
		for player in world_state_buffer[1]["Players"].keys():
			if player == get_tree().get_network_unique_id():
				continue
			if not world_state_buffer[0]["Players"].has(player):
				continue
			if get_node("OtherPlayers").has_node(str(player)):
				var new_position = lerp(world_state_buffer[0]["Players"][player]["P"],world_state_buffer[1]["Players"][player]["P"], interpolation_factor)
				var new_rotation = interpolate_y_rotation(world_state_buffer[0]["Players"][player]["R"],world_state_buffer[1]["Players"][player]["R"], interpolation_factor)
				get_node("OtherPlayers/" + str(player)).MovePlayer(new_position, new_rotation)
				get_node("OtherPlayers/" + str(player)).is_moving = world_state_buffer[1]["Players"][player]["M"]
				get_node("OtherPlayers/" + str(player)).is_jumping = world_state_buffer[1]["Players"][player]["J"]
				get_node("OtherPlayers/" + str(player)).casting = world_state_buffer[1]["Players"][player]["C"]
			else:
				if not player in disconnect_queue:
					SpawnNewPlayer(player, world_state_buffer[1]["Players"][player]["P"])
		######### syncing enemy state
		for enemy in world_state_buffer[1]["Enemies"].keys():
			if not world_state_buffer[0]["Enemies"].has(enemy):
				continue
			if get_node("Enemies").has_node(str(enemy)):
				if world_state_buffer[1]["Enemies"][enemy]["EnemyState"] == "Dead":
					handle_enemy_died(enemy)
					
				var new_position = lerp(world_state_buffer[0]["Enemies"][enemy]["EnemyLocation"],world_state_buffer[1]["Enemies"][enemy]["EnemyLocation"], interpolation_factor)
				get_node("Enemies/" + str(enemy)).MoveEnemy(new_position)
				get_node("Enemies/" + str(enemy)).setHealth(world_state_buffer[1]["Enemies"][enemy]["EnemyHealth"])
				
			else:
				if not enemy in despawn_queue:
					SpawnNewEnemy(enemy, world_state_buffer[1]["Enemies"][enemy])
	
func update_world_state(world_state):
	# Extrapolate
	# Rubber Banding
	if world_state["T"] > last_world_state:
		last_world_state = world_state["T"]
		world_state_buffer.append(world_state)
		

func handle_enemy_died(enemy_id):
	var enemy = get_node("Enemies/" + str(enemy_id))
	if !enemy.dead:
		enemy.die()
		get_node("Player").notify_enemy_died(enemy_id)
	
