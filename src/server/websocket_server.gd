extends Node

class_name WebSocketServer

signal client_connected(player_id: int)
signal client_disconnected(player_id: int)
signal message_received(player_id: int, message: Dictionary)

var tcp_server = TCPServer.new()
var websocket_peers: Dictionary = {}  # Maps client_id to WebSocketPeer
var clients: Dictionary = {}  # Maps client_id to player_id
var next_player_id: int = 1
var next_client_id: int = 0
var message_handlers: Dictionary = {}

func _ready() -> void:
	if tcp_server.listen(8080) != OK:
		push_error("Failed to start WebSocket server on port 8080")
		return
	
	print("WebSocket server listening on port 8080")
	set_process(true)

func _process(_delta: float) -> void:
	# Accept new connections
	if tcp_server.is_connection_available():
		var tcp_stream = tcp_server.take_connection()
		var ws_peer = WebSocketPeer.new()
		ws_peer.accept_stream(tcp_stream)
		
		var client_id = next_client_id
		next_client_id += 1
		websocket_peers[client_id] = ws_peer
		print("New TCP connection, assigned client_id: %d" % client_id)
	
	# Poll all WebSocket peers
	var disconnected_clients = []
	for client_id in websocket_peers.keys():
		var ws_peer = websocket_peers[client_id]
		ws_peer.poll()
		
		var state = ws_peer.get_ready_state()
		if state == WebSocketPeer.STATE_CLOSED:
			disconnected_clients.append(client_id)
			continue
		
		# Handle incoming messages
		while ws_peer.get_available_packet_count():
			var data = ws_peer.get_packet()
			if data == null:
				continue
			
			var message_string = data.get_string_from_utf8()
			_handle_message(client_id, message_string)
	
	# Clean up disconnected clients
	for client_id in disconnected_clients:
		websocket_peers.erase(client_id)
		if client_id in clients:
			var player_id = clients[client_id]
			clients.erase(client_id)
			client_disconnected.emit(player_id)
			print("Player %d (client %d) disconnected" % [player_id, client_id])

func _handle_message(client_id: int, message_string: String) -> void:
	var message = JSON.parse_string(message_string)
	if message == null:
		_send_error(client_id, "INVALID_JSON", "Failed to parse JSON message")
		return
	
	message_received.emit(clients.get(client_id, -1), message)
	
	var message_type = message.get("type", "")
	if message_type in message_handlers:
		message_handlers[message_type].call(client_id, message)

func add_message_handler(message_type: String, handler: Callable) -> void:
	message_handlers[message_type] = handler

func register_client(client_id: int) -> int:
	var player_id = next_player_id
	clients[client_id] = player_id
	next_player_id += 1
	
	client_connected.emit(player_id)
	print("Client %d connected as Player %d" % [client_id, player_id])
	
	return player_id

func unregister_client(client_id: int) -> void:
	var player_id = clients.get(client_id, -1)
	if player_id != -1:
		clients.erase(client_id)
		client_disconnected.emit(player_id)
		print("Player %d disconnected" % player_id)

func broadcast(message: Dictionary) -> void:
	var json_str = JSON.stringify(message)
	var buffer = json_str.to_utf8_buffer()
	
	for client_id in clients.keys():
		if client_id in websocket_peers:
			websocket_peers[client_id].send(buffer)

func send_to_player(client_id: int, message: Dictionary) -> void:
	var json_str = JSON.stringify(message)
	var buffer = json_str.to_utf8_buffer()
	
	if client_id in websocket_peers:
		websocket_peers[client_id].send(buffer)
	else:
		push_warning("send_to_player: client %d not found" % client_id)

func _send_error(client_id: int, code: String, message_text: String) -> void:
	var error_msg = {
		"type": "error",
		"timestamp": Time.get_ticks_msec(),
		"data": {
			"code": code,
			"message": message_text,
			"severity": "error"
		}
	}
	send_to_player(client_id, error_msg)

func get_player_id_from_client(client_id: int) -> int:
	return clients.get(client_id, -1)

func get_all_player_ids() -> Array:
	return clients.values()
