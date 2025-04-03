@icon("res://mpc-addons/MPDiscovery/MPDiscovery.svg")
extends MPExtension
## Local LAN game discovery
class_name MPDiscovery

## Port to discover servers on
@export var discover_port: int = 4222

## Amount of time to resend discovery message (in seconds)
@export var scan_interval_sec: float = 2

## Server metadata directory
var server_metadata := {}
## Server Unique ID
var server_uid = ""
var lan_server: UDPServer
var lan_client: PacketPeerUDP
var broadcasting := false
var scanning := false
var scan_timer: Timer
# Discovered server UIDs
var _discovered_uid = []

signal server_found(data: DiscoveredServer)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	mpc.server_started.connect(_server_started)
	mpc.server_stopped.connect(_server_stopped)
	mpc.player_connected.connect(_player_count_change)
	mpc.player_disconnected.connect(_player_count_change)
	mpc.connected_to_server.connect(_player_count_change)

func _player_count_change(_plr):
	server_metadata.player_count = mpc.player_count

func _server_started():
	server_uid = str(round(Time.get_unix_time_from_system() * 1000))
	server_metadata.max_player_count = mpc.max_players
	server_metadata.player_count = 0
	lan_server = UDPServer.new()
	lan_server.listen(discover_port, '0.0.0.0')
	server_metadata.port = mpc.port
	broadcasting = true

func _server_stopped():
	lan_server.stop()
	broadcasting = false

## Clear discovered servers cache data
func clear_discovered_cache():
	_discovered_uid = []

## Start server discovery
func start_scan():
	if scanning:
		MPIO.logwarn("start_scan: The scan has already started!")
		return
	clear_discovered_cache()
	scanning = true
	lan_client = PacketPeerUDP.new()
	lan_client.set_broadcast_enabled(true)
	lan_client.set_dest_address("255.255.255.255", discover_port)
	fire_discover()
	
	scan_timer = Timer.new()
	add_child(scan_timer)
	scan_timer.timeout.connect(_scan_timer_loop)
	scan_timer.start(scan_interval_sec)

func _scan_timer_loop():
	fire_discover()
	scan_timer.start(scan_interval_sec)

## Fire discover message
func fire_discover():
	lan_client.put_var({"type":"discover"})

## Stop server discovery
func stop_scan():
	if !scanning:
		MPIO.logwarn("start_scan: The scan has already stopped!")
		return
	scanning = false
	lan_client.close()
	scan_timer.stop()
	scan_timer.queue_free()

func _process(delta):
	# Handle server messages
	if scanning:
		if lan_client.get_available_packet_count() > 0:
			var data = lan_client.get_packet().decode_var(0)
			if data.has("type") and data["type"] == "metadata":
				var server_ip = lan_client.get_packet_ip()
				var server_uid = data.uid
				
				if _discovered_uid.has(server_uid):
					return
				
				_discovered_uid.append(server_uid)
				
				var discovered_server := DiscoveredServer.new()
				discovered_server.connect_url = server_ip + ":" + str(data.metadata.port)
				discovered_server.ip = server_ip
				discovered_server._mpc = mpc
				discovered_server.ping_ms = (Time.get_unix_time_from_system() - data.recv_time) * 1000
				discovered_server.metadata = data.metadata
				discovered_server.uid = str(server_uid)
				server_found.emit(discovered_server)
	
	# Handle client messages
	if broadcasting:
		lan_server.poll()
		if lan_server.is_connection_available():
			var peer: PacketPeerUDP = lan_server.take_connection()
			var data = peer.get_packet().decode_var(0)
			if data.has("type") and data["type"] == "discover":
				peer.put_var({
					"type":"metadata",
					"metadata": server_metadata,
					"recv_time": Time.get_unix_time_from_system(),
					"uid": server_uid
				})
