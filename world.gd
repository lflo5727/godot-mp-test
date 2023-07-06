extends Node

@onready var mainMenu = $CanvasLayer/MainMenu
@onready var addressEntry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry

const Player = preload("res://player.tscn")
const PORT = 9999
var enetPeer = ENetMultiplayerPeer.new()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

# Handle the host button being pressed
func _on_host_button_pressed():
	mainMenu.hide()

	enetPeer.create_server(PORT)	
	multiplayer.multiplayer_peer = enetPeer
	
	# Add player instances when peers connect
	multiplayer.peer_connected.connect(add_player)
	
	# Spawn host player
	add_player(multiplayer.get_unique_id())


func _on_join_button_pressed():
	mainMenu.hide()
	
	enetPeer.create_client("localhost", PORT)	
	multiplayer.multiplayer_peer = enetPeer

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
