extends Control

@export var discovery: MPDiscovery


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	discovery.server_found.connect(_server_found)
	discovery.start_scan()

func _server_found(server: DiscoveredServer):
	var card = preload("res://mpc-addons/MPDiscovery/demo/server_card.tscn").instantiate()
	card.get_node("URLLabel").text = server.connect_url
	card.get_node("PingMs").text = str(round(server.ping_ms)) + "ms"
	card.get_node("PlayerCount").text = str(server.metadata.player_count) + "/" + str(server.metadata.max_player_count)
	card.get_node("UIDLabel").text = server.uid
	card.get_node("JoinBtn").pressed.connect(_join_server.bind(server))
	%Listing.add_child(card)

func _join_server(server: DiscoveredServer):
	server.connect_to_server()
