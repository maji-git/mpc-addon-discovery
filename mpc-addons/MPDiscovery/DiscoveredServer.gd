extends Object
## Discovered server object, from MPDiscovery addon
class_name DiscoveredServer

## Server's IP
var ip := ""
## Connect URL to use with MPC
var connect_url := ""
var _mpc: MultiPlayCore
## Ping in milliseconds
var ping_ms: float = 0
## Server's metadata
var metadata: Dictionary = {}
## Server's unique discovery ID
var uid := ""

func _init() -> void:
	pass

## Connect to this discovered server
func connect_to_server(handshake_data: Dictionary = {}, credentials_data: Dictionary = {}):
	_mpc.start_online_join(connect_url, handshake_data, credentials_data)
