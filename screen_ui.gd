extends Node2D

var scannedSoFar = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func _on_player_fp_scan_planet(planetStats, planetClassification, planetName):
	SetPlanetStats(planetStats, planetClassification)
	
	# add to scanned list
	scannedSoFar.append([planetName, planetStats, planetClassification])

func PlanetJustEntered(planetName, planetStats, planetClassification):
	for scannedPlanet in scannedSoFar:
		if scannedPlanet[0] == planetName:
			# scanned planet before, populate fields
			SetPlanetStats(scannedPlanet[1], scannedPlanet[2])
			return # done
	
	# reset all stats
	for key in PlayerStats.stats.keys():
		get_node("scan menu/labels/" + key + "_amount").text = key + ": " + "unknown"
	$"scan menu/labels/classification".text = "Classification: unknown"
	$"scan menu/Scan_button".text = "Scan planet (v)"

func SetPlanetStats(planetStats, planetClassification):
	# set stats
	for key in planetStats.keys():
		get_node("scan menu/labels/" + key + "_amount").text = key + ": " + str(round(planetStats[key])) + "%"
	# set classification
	var classificationList = ["barren", "abundant", "bountiful", "superabundant"]
	var classificationText = classificationList[planetClassification-1]
	$"scan menu/labels/classification".text = "Classification:" + classificationText
	
	# show that it's been scanned
	$"scan menu/Scan_button".text = "Scanned!"
