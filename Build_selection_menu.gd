extends Node2D

@onready var scroll1ScrollContainer = $"carousels/scroll 1/scroll"
@onready var scroll1ObjectContainer = $"carousels/scroll 1/scroll/HBoxContainer"
@onready var scroll2ScrollContainer = $"carousels/scroll 2/scroll"
@onready var scroll2ObjectContainer = $"carousels/scroll 2/scroll/HBoxContainer"
@onready var scroll3ScrollContainer = $"carousels/scroll 3/scroll"
@onready var scroll3ObjectContainer = $"carousels/scroll 3/scroll/HBoxContainer"
@export var exchangerDesc: RichTextLabel

var scroll1Index
var scroll2Index 
var scroll3Index

signal SwappedBuilding

# Called when the node enters the scene tree for the first time.
func _ready():
	scroll1Index = 0
	scroll2Index = 0
	scroll3Index = 0
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Note: modulo and such is for carousel illusion (first and last elements fake)
	if Input.is_action_just_pressed("swap_building"):
		scroll1Index += 1
		scroll1Index = (scroll1Index % (scroll1ObjectContainer.get_child_count()-2))
		SwappedBuilding.emit()
	
	if Input.is_action_just_pressed("swap_resource_type"):
		scroll2Index += 1
		scroll2Index = (scroll2Index % (scroll2ObjectContainer.get_child_count()-2))
	
	if Input.is_action_just_pressed("swap_exchange_resource_type"):
		scroll3Index += 1
		scroll3Index = (scroll3Index % (scroll3ObjectContainer.get_child_count()-2))
	
	# hide 3rd bar if not selecting exchangers
	if scroll1Index == 1:
		scroll3ScrollContainer.get_parent().show()
		exchangerDesc.show()
	else:
		scroll3ScrollContainer.get_parent().hide()
		exchangerDesc.hide()
	
	# only show resources that aren't selected in the second scroll menu
	var resources = ["Fuel", "Energy", "Ore", "Gold", "Research"]
	resources.pop_at(scroll2Index)
	var i = 0
	for child in scroll3ObjectContainer.get_children():
		if child is Label:
			child.text = resources[i]
			i += 1
	
	#scroll bar 1
	var scroll1Target = ScrollToElement(scroll1Index+1, scroll1ScrollContainer, scroll1ObjectContainer)
	scroll1ScrollContainer.scroll_horizontal = lerpf(scroll1ScrollContainer.scroll_horizontal, scroll1Target, 0.3)
	
	#scroll bar 2
	var scroll2Target = ScrollToElement(scroll2Index+1, scroll2ScrollContainer, scroll2ObjectContainer)
	scroll2ScrollContainer.scroll_horizontal = lerpf(scroll2ScrollContainer.scroll_horizontal, scroll2Target, 0.3)

	#scroll bar 2
	var scroll3Target = ScrollToElement(scroll3Index+1, scroll3ScrollContainer, scroll3ObjectContainer)
	scroll3ScrollContainer.scroll_horizontal = lerpf(scroll3ScrollContainer.scroll_horizontal, scroll3Target, 0.3)

	
	# fade effect
	FadeEffect(scroll1ScrollContainer, scroll1ObjectContainer)
	FadeEffect(scroll2ScrollContainer, scroll2ObjectContainer)
	FadeEffect(scroll3ScrollContainer, scroll3ObjectContainer)

func GetIndices():
	return [scroll1Index, scroll2Index, scroll3Index]

func ScrollToElement(tempIndex: int, scrollContainer: ScrollContainer, objectContainer: HBoxContainer):
	# calculate target if the text is supposed to be anchored left
	var targetForLeftAnchor = 0
	var scrollObjectsList = objectContainer.get_children()
	assert(tempIndex>0, "missing spacing elements in hbox container")
	for i in range(tempIndex):
		targetForLeftAnchor += scrollObjectsList[i].size.x
		targetForLeftAnchor += objectContainer.get_theme_constant("separation")
	# convert to middle alignment
	var scrollTarget = targetForLeftAnchor - scrollContainer.size.x/2 + scrollObjectsList[tempIndex].size.x/2
	return scrollTarget

func FadeEffect(scrollContainer:ScrollContainer, scrollObjectsParent: HBoxContainer):
	var targetPosition = scrollContainer.global_position.x + scrollContainer.size.x/2
	for item in scrollObjectsParent.get_children():
		if item is Label:
			# get dist, adjusting for the fact that it uses left anchor
			var dist = abs((item.global_position.x+item.size.x/2) - targetPosition)
			var alpha = max(1-pow(dist/scrollContainer.size.x*2, 2), 0.15)
			item.add_theme_color_override("font_color", Color(1, 1, 1, alpha))


