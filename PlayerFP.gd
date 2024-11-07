extends CharacterBody3D

@export var DEBUG = false

const SPEED = 1
const MAX_SPEED = 3
const JUMP_VELOCITY = 4
const mouseSensitivity = 0.01

var gravityStrength = 0.12
var cameraRotation = Vector2.ZERO
var planetNode: Node3D = null
var hologramShader = preload("res://shaders/hologram.gdshader")

var buildMenuOpen = false

signal scan_planet(planetStats)

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	floor_max_angle = 90 # degrees
	LoadPreviewMesh(0)
	
	var buildScreen = $"camera/UIscreen/SubViewport/screenUI/Build_selection_menu/"
	buildScreen.SwappedBuilding.connect(_on_swap_building)

# swap the building
func _on_swap_building():
	var screenUI = $"camera/UIscreen/SubViewport/screenUI/Build_selection_menu/"
	var buildingTypeIndex = screenUI.GetIndices()[0]
	LoadPreviewMesh(buildingTypeIndex)

func fiLerp(smoothing: float, deltaTime: float):
	return 1 - pow(1-smoothing, deltaTime)

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# open build menu
	if Input.is_action_just_pressed("open_build_menu"):
		buildMenuOpen = not buildMenuOpen
	
	# deal with build menu
	var UIscreen = $"camera/UIscreen"
	if buildMenuOpen:
		UIscreen.position = lerp(UIscreen.position, Vector3(0.1, -0.05, -0.2), fiLerp(0.999, delta))
	else:
		UIscreen.position = lerp(UIscreen.position, Vector3(0.3, -0.2, -0.2), fiLerp(0.999, delta))
	UIscreen.look_at($"camera".global_position) # look at cam
	# fix rotation
	UIscreen.rotation.z = 0
	UIscreen.rotation.y += PI
	UIscreen.rotation.x = -UIscreen.rotation.x
	
	# orient building preview
	var gravityDirNormal = Vector3.UP
	var ray: RayCast3D = $camera/raycastForward
	var buildingPreview = ray.get_node("buildingPreview")
	if planetNode != null:
		gravityDirNormal = (planetNode.position - self.position).normalized()
	
	if ray.is_colliding() and buildMenuOpen:
		var buildingSize = 0.1
		var norm = ray.get_collision_normal()
		
		var pos = ray.get_collision_point() + norm * buildingSize
		buildingPreview.global_transform.origin = pos
		buildingPreview.global_transform.basis = buildingPreview.global_transform.basis.slerp(GetUpdatedBasisFromUp(norm, buildingPreview.global_transform.basis),fiLerp(0.99, delta))
		buildingPreview.show()
		
		# place building. TD: check collider is planet
		if Input.is_action_just_pressed("place_building"):
			if GetNumberBuildingsOnPlanet() < PlayerStats.maxBuildingsOnPlanets:
				var screenUI = $"camera/UIscreen/SubViewport/screenUI/Build_selection_menu"
				var indices = screenUI.GetIndices()
				AddBuildingToPlanet(buildingPreview.global_transform, buildingPreview.mesh, indices)
				SetPlaceableOrUnplaceableMaterialForPreview()
	else:
		buildingPreview.hide()
	
	# scanning planet
	if Input.is_action_just_pressed("scan_planet"):
		ScanPlanet()
	
	# platforming stuff
	up_direction = -gravityDirNormal
	
	var targetBasis = GetUpdatedBasisFromUp(-gravityDirNormal, self.basis)
	#assert(basis == basis.orthonormalized(), "basis not normalized: " + str(basis) + ". Target basis " + str(targetBasis))
	basis = basis.slerp(targetBasis, 0.6)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var inputDir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var inputUpDown = Input.get_axis("move_down", "move_up")
	var direction = (self.basis * Vector3(inputDir.x, 0, inputDir.y).rotated(Vector3.UP, cameraRotation.x)).normalized()
	if DEBUG:
		direction = ($camera.basis * Vector3(inputDir.x, inputUpDown, inputDir.y)).normalized()
	
	# deal with input
	if direction != Vector3.ZERO:
		var testVelocity = velocity + direction * SPEED
		# use max velocity
		var velocityTowardsPlanet = VectorResolute(testVelocity, -self.basis.y)
		var velocityPerpendicularToPlanet = testVelocity - velocityTowardsPlanet
		# clamp motion side to side (not jump) to max speed
		velocityPerpendicularToPlanet =  velocityPerpendicularToPlanet.normalized() * clamp(velocityPerpendicularToPlanet.length(), 0, MAX_SPEED)
		# set final velocity
		velocity = velocityTowardsPlanet + velocityPerpendicularToPlanet
	else:
		# slows down movement but not in gravity dir.
		velocity = velocity.move_toward(Vector3.ZERO+VectorResolute(velocity, -self.basis.y), SPEED)
	
	if Input.is_action_pressed("fp_jump") and is_on_floor():
		velocity += (self.basis.y * JUMP_VELOCITY)
	
	if not is_on_floor():
		velocity -= self.basis.y * gravityStrength
	
	move_and_slide()
	
	# lock camera rotation so player can't look upside down and get confused
	cameraRotation.y = clamp(cameraRotation.y, -PI/2, PI/2)

func VectorResolute(vectorToProject, projectOnto) -> Vector3:
	var projectOntoNormalised = projectOnto.normalized()
	return (vectorToProject.dot(projectOntoNormalised)) * projectOntoNormalised

func GetUpdatedBasisFromUp(upDirection: Vector3, currentBasis: Basis):
	var separationAxis = currentBasis.y.cross(upDirection).normalized()
	# angle between vectors (using dot(a,b)=|a||b|cos(theta))
	var separationAngle = acos(clamp(upDirection.dot(currentBasis.y), -1, 1))
	# rotate basis along this axis by this angle to fix the rotation
	var targetBasis = currentBasis
	if separationAxis != Vector3.ZERO:
		targetBasis = basis.rotated(separationAxis, separationAngle)
	return targetBasis.orthonormalized()

func AddBuildingToPlanet(buildingTransformGlobal: Transform3D, meshToInstance: Mesh, indices):
	# get instanced building mesh
	var instance = MeshInstance3D.new()
	instance.mesh = meshToInstance
	# instance the mesh
	planetNode.add_child(instance)
	instance.global_transform = buildingTransformGlobal
	
	var buildingType = indices[0]
	var buildResourceType: String = PlayerStats.stats.keys()[indices[1]]
	# exchange type index does not include all stats (indices[1] missing)
	var statsRemovedMissingStat = PlayerStats.stats.keys()
	statsRemovedMissingStat.remove_at(indices[1])
	var buildExchangeType: String = statsRemovedMissingStat[indices[2]]
	if buildingType == 0: # need to mod
		planetNode.buildings.append({"type": "generator", "resource": buildResourceType})
	elif buildingType == 1:
		planetNode.buildings.append({"type": "exchanger", "resourceGain": buildExchangeType, "resourceLose": buildResourceType})
	else:
		planetNode.buildings.append({"type": "refiner", "resource": buildResourceType})

func GetNumberBuildingsOnPlanet():
	if planetNode == null:
		return 0
	return len(planetNode.buildings)

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cameraRotation += Vector2(-event.relative.x, -event.relative.y) * mouseSensitivity
		$camera.rotation = Vector3(cameraRotation.y, cameraRotation.x, 0)

func LoadPreviewMesh(index: int):
	var dir = DirAccess.open("res://buildings/preview_meshes")
	var files = dir.get_files()
	var dirLength = len(files)
	index *= 2
	index = index % dirLength # loop around
	
	var fileName = "res://buildings/preview_meshes/" + files[index]
	
	# get meshinstance from GLB file
	var sceneWithPreviewMesh: PackedScene = load(fileName)
	assert(sceneWithPreviewMesh != null, "loading preview mesh failed. File path: " + fileName)
	var previewMeshNode = sceneWithPreviewMesh.instantiate().get_child(0).get_child(0)
	
	var buildingPreviewNode = $camera/raycastForward/buildingPreview
	
	# load building mesh to preview mesh
	buildingPreviewNode.mesh = previewMeshNode.mesh

	# load shader (preloaded) onto each material
	var shader = ShaderMaterial.new()
	shader.shader = hologramShader
	for i in range(previewMeshNode.get_surface_override_material_count()):
		buildingPreviewNode.set_surface_override_material(i, shader)
	
	SetPlaceableOrUnplaceableMaterialForPreview()

func SetPlaceableOrUnplaceableMaterialForPreview():
	# set blue or red material depending on whether can be placed or not
	var buildingPreviewNode = $camera/raycastForward/buildingPreview
	if GetNumberBuildingsOnPlanet() < PlayerStats.maxBuildingsOnPlanets: #placeable
		for i in range(buildingPreviewNode.get_surface_override_material_count()):
			var mat = buildingPreviewNode.get_surface_override_material(i)
			mat.set_shader_parameter("baseColour", Color(0.2, 0.71, 0.9))
	else: # unplaceable
		for i in range(buildingPreviewNode.get_surface_override_material_count()):
			var mat = buildingPreviewNode.get_surface_override_material(i)
			mat.set_shader_parameter("baseColour", Color.RED)

func ScanPlanet():
	if planetNode != null:
		scan_planet.emit(planetNode.planetStats, planetNode.classification, planetNode.name)





