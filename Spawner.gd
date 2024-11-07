extends Node3D

@export var planetScene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	var currentRadius = 40
	randomize()
	# generate planets
	var planetNum = randi_range(12, 25)
	for i in range(planetNum):
		var object = planetScene.instantiate()
		object.orbitRadius = currentRadius
		currentRadius += randi_range(40, 100)
		object.orbitSpeed = 0#randf_range(0.1, 0.4)
		object.name = "planet " + str(i)
		call_deferred("add_child",object)
		
		# connect area signals
		var area3D: Area3D
		for child in object.get_children():
			if child is Area3D:
				area3D = child
		
		var player = get_parent().get_node("cameraController/playerShip")
		
		area3D.connect("body_entered", player.on_enter_planet_area.bind(object))
		area3D.connect("body_exited", player.on_exit_planet_area.bind(object))
		
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
