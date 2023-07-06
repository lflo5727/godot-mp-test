extends Node

@onready var mainMenu = $CanvasLayer/MainMenu
@onready var addressEntry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $CanvasLayer/HUD
@onready var healthBar = $CanvasLayer/HUD/HealthBar

const Player = preload("res://player.tscn")
const PORT = 9999
var enetPeer = ENetMultiplayerPeer.new()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

# Handle the host button being pressed
func _on_host_button_pressed():
	mainMenu.hide()
	hud.show()

	enetPeer.create_server(PORT)	
	multiplayer.multiplayer_peer = enetPeer
	
	# Add player instances when peers connect
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	# Spawn host player
	add_player(multiplayer.get_unique_id())


func _on_join_button_pressed():
	mainMenu.hide()
	hud.show()
	
	enetPeer.create_client("localhost", PORT)	
	multiplayer.multiplayer_peer = enetPeer

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)
		
func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
	
func update_health_bar(health_value):
	healthBar.value = health_value

func _on_multiplayer_spawner_spawned(player):
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)
