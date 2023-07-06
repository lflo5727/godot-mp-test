extends CharacterBody3D

@onready var camera = $Camera3D
@onready var animPlayer = $AnimationPlayer
@onready var muzzleFlash = $Camera3D/pistol/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D

var health = 3

const SPEED = 10
const JUMP_VELOCITY = 7

signal health_changed(health_value)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	# Check if is correct player to control
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.005)
		camera.rotate_x(-event.relative.y * 0.005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		
	if Input.is_action_just_pressed("shoot") and animPlayer.current_animation != "shoot":
		play_shoot_effects.rpc()
		
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			# rpc_id calls only on single, whereas rpc would call on all players
			hit_player.recieve_damage.rpc_id(hit_player.get_multiplayer_authority())
	
func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	if animPlayer.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		animPlayer.play("move")
	else:
		animPlayer.play("idle")

	move_and_slide()
	
# call_local lets us still call this locally, but propagates to other players
@rpc("call_local")
func play_shoot_effects():
	animPlayer.stop()
	animPlayer.play("shoot")
	muzzleFlash.restart()

# any_peer allows us to call this method on an instance of Player from another instance
@rpc("any_peer")
func recieve_damage():
	health -= 1
	if health <= 0:
		health = 3
		position = Vector3.ZERO
		
	health_changed.emit(health)

func _on_animation_player_animation_finished(anim_name):
	# This resets the animation for all players to see, probably a better way to scale this
	if anim_name == "shoot":
		animPlayer.play('idle')
