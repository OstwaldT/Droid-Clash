extends Node

class_name MainServer

var ws_server: WebSocketServer
var game_manager: GameManager
var message_handler: MessageHandler
var status_panel: ServerStatusPanel

func _ready() -> void:
	print("Initializing Droid-Clash Server...")
	
	# Create game manager
	game_manager = GameManager.new()
	add_child(game_manager)
	
	# Create WebSocket server
	ws_server = WebSocketServer.new()
	add_child(ws_server)
	
	# Create message handler
	message_handler = MessageHandler.new(ws_server, game_manager)
	
	# Create server status panel
	status_panel = ServerStatusPanel.new()
	add_child(status_panel)
	
	print("Server initialized and ready for connections")

func _process(_delta: float) -> void:
	# Game loop can be implemented here if needed
	pass
