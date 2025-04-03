extends Object
class_name DiscoveredServer

var ip := ""
var connect_url := ""
var _mpc: MultiPlayCore
var ping_ms: float = 0
var metadata: Dictionary = {}
var uid := ""

func _init() -> void:
	pass

func connect_to_server(handshake_data: Dictionary = {}, credentials_data: Dictionary = {}):
	_mpc.start_online_join(connect_url, handshake_data, credentials_data)
