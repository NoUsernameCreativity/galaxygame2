extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$"Control/ColorRect/HBoxContainer/Label/num".text = str(round(PlayerStats.stats["fuel"]))
	$"Control/ColorRect/HBoxContainer/Label2/num".text = str(round(PlayerStats.stats["energy"]))
	$"Control/ColorRect/HBoxContainer/Label5/num".text = str(round(PlayerStats.stats["ore"]))
	$"Control/ColorRect/HBoxContainer/Label3/num".text = str(round(PlayerStats.stats["gold"]))
	$"Control/ColorRect/HBoxContainer/Label4/num".text = str(round(PlayerStats.stats["research"]))
	pass
