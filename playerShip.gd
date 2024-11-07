extends Node3D

const stillThreshold = 0.4
const dismountTimeThreshold = 1

var cameraRotation = Vector2.ZERO
var currentPlanetArea = null
const mouseSensitivity = 0.005
const speed = 60

# vars to do with allowing the player to dismount
var stillTimer = 0
var noThrottleTimer = 0
var canDismount = false

var controlsEnabled = true

@onready var rigidbody = $rigidbody
@onready var camera = $camera

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	var throttle
	if controlsEnabled:
		throttle = Input.get_axis("ship_throttle", "ship_brake")
		if Input.is_action_just_pressed("ui_cancel"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# deal with dismount timer
	if $rigidbody.linear_velocity.length() < stillThreshold:
		stillTimer += delta
	else:
		stillTimer = 0
		
	
	if throttle == 0:
		noThrottleTimer += delta
	else:
		noThrottleTimer = 0
	
	canDismount = false
	if noThrottleTimer > dismountTimeThreshold and stillTimer > dismountTimeThreshold:
		if currentPlanetArea != null:
			canDismount = true

	camera.position = rigidbody.position # child camera position to rigidbody. Can add custom camera controls here later.
	


func on_enter_planet_area(rigidBody: Node3D, planetEntered: Node3D):
	print("body entered:" + planetEntered.name)
	if rigidBody == $rigidbody: # own rigidbody
		currentPlanetArea = planetEntered

func on_exit_planet_area(rigidBody: Node3D, planetExited: Node3D):
	print("body exited:" + planetExited.name)
	if currentPlanetArea != null and rigidBody == $rigidbody:
		if currentPlanetArea.name == planetExited.name:
			currentPlanetArea = null

func _physics_process(delta):
	if controlsEnabled:
		var throttle = Input.get_axis("ship_throttle", "ship_brake")
		var forceVector = -(camera.basis * Vector3.FORWARD*throttle).normalized() * speed
	
		rigidbody.apply_central_force(forceVector)

func _input(event):
	if controlsEnabled:
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			cameraRotation += Vector2(-event.relative.x, -event.relative.y) * mouseSensitivity
			camera.rotation = Vector3(cameraRotation.y, cameraRotation.x, 0)

	


