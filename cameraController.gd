extends Node3D

@onready var playerFP = $playerFP
@onready var playerShip = $playerShip
@export var generalUI: Node2D

const remountShipDistanceThreshold = 10

var view = "shipView"

# Called when the node enters the scene tree for the first time.
func _ready():
	# disable at beginning (ship first)
	playerFP.set_process_mode(self.PROCESS_MODE_DISABLED)
	playerFP.hide()
	$playerShip/camera.current = true
	# hide ship while flying
	playerShip.get_node("rigidbody/spaceship1").hide()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ship_dismount"):
		if view == "shipView":
			if playerShip.canDismount:
				playerFP.position = playerShip.get_node("rigidbody").position 
				# TD: move player away from ship
				var up = (playerFP.global_position-playerShip.currentPlanetArea.global_position).normalized()
				playerFP.global_position += up * 1.5
				# rest
				playerFP.show()
				playerFP.set_process_mode(self.PROCESS_MODE_INHERIT)
				playerShip.controlsEnabled = false
				$playerFP/camera.current = true
				playerFP.planetNode = playerShip.currentPlanetArea
				playerFP.get_node("camera/UIscreen/SubViewport/screenUI").PlanetJustEntered(playerFP.planetNode.name, playerFP.planetNode.planetStats, playerFP.planetNode.classification)
				view = "fpView"
				# show ship
				playerShip.get_node("rigidbody/spaceship1").show()
				# load preview mesh colour in case changed planet (and menu is still same)
				playerFP.SetPlaceableOrUnplaceableMaterialForPreview()
		else:
			if (playerFP.position-$playerShip/rigidbody.position).length() < remountShipDistanceThreshold:
				playerFP.hide()
				playerFP.set_process_mode(self.PROCESS_MODE_DISABLED)
				playerShip.controlsEnabled = true
				$playerShip/camera.current = true
				view = "shipView"
				
				# hide ship while flying
				playerShip.get_node("rigidbody/spaceship1").hide()
	# text hints
	if view == "shipView":
		if playerShip.canDismount:
			# set text hint for dismount
			generalUI.get_node("Control2/textHint").text = "Press G to dismount"
		else:
			# set text hint for get close to dismount
			generalUI.get_node("Control2/textHint").text = "Land on planet to dismount"
	else:
		generalUI.get_node("Control2/textHint").text = "Press B to open/close build menu (look at planet to build)"
	pass
