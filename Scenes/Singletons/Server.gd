extends Node

var network = NetworkedMultiplayerENet.new()
var ip = "192.168.2.33"
var port = 1909

var decimal_collector = 0
var latency = 0
var latency_array = []
var client_clock = 0
var delta_latency = 0

func _physics_process(delta):
	client_clock += int(delta * 1000) + delta_latency
	delta_latency = 0
	decimal_collector += (delta * 1000) - int(delta * 1000)
	if decimal_collector >= 1.00:
		client_clock += 1
		decimal_collector -= 1.00
	
func ConnectToServer():
	network.create_client(ip, port)
	get_tree().set_network_peer(network)
	
	network.connect("connection_failed", self, "_OnConnectionFailed")
	network.connect("connection_succeeded", self, "_OnConnectionSucceeded")
	
func _OnConnectionFailed():
	print("Failed To Connect")
	
func _OnConnectionSucceeded():
	print("Succesfully Connected")
	rpc_id(1, "FetchServerTime", OS.get_system_time_msecs())
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.connect("timeout", self, "DetermineLatency")
	self.add_child(timer)
	
func SendPlayerState(player_state):
	rpc_unreliable_id(1, "RecievePlayerState", player_state)
	
remote func SpawnNewPlayer(player_id, spawn_position):
	get_node("../World").SpawnNewPlayer(player_id, spawn_position)

remote func DespawnNewPlayer(player_id):
	get_node("../World").DespawnNewPlayer(player_id)
	
remote func RecieveWorldState(world_state):
	get_node("../World").update_world_state(world_state)

remote func ReturnServerTime(server_time, client_time):
	latency = (OS.get_system_time_msecs() - client_time) / 2
	client_clock = server_time + latency
	
func DetermineLatency():
	rpc_id(1, "DetermineLatency", OS.get_system_time_msecs())
	
remote func ReturnLatency(timestamp):
	latency_array.append((OS.get_system_time_msecs() - timestamp) / 2)
	if latency_array.size() == 9:
		var total_latency = 0
		latency_array.sort()
		var mid_point = latency_array[4]
		for i in range(latency_array.size()-1, -1, -1):
			if latency_array[i] > (2 * mid_point) and latency_array[-1] > 20:
				latency_array.remove(i)
			else:
				total_latency += latency_array[i]
		delta_latency = (total_latency / latency_array.size()) - latency
		latency = total_latency / latency_array.size()
		latency_array.clear()
		
func notify_cast_start(target, spell_id):
	rpc_id(1, "start_cast", target, spell_id)
	pass
	
remote func notify_cast_finished():
	get_node("../World/Player").finish_cast()
	pass
	
	
	
	
	
	
