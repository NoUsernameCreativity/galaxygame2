extends Node3D

@export var orbitRadius: float
@export var orbitSpeed: float
@export var shaderMaterialExport: ShaderMaterial

var orbitRotation = 0

var planetStats = {
	"fuel": 0,
	"energy": 0,
	"ore": 0,
	"gold": 0,
	"research": 0
}

var buildings = []

var classification = 0
var radius

# Called when the node enters the scene tree for the first time.
func _ready():
	orbitRotation = randf_range(0, 2*PI)
	# generation stuff
	GenerateStats()
	GenerateMesh()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = orbitRadius * Vector3.FORWARD.rotated(Vector3.UP, orbitRotation)
	orbitRotation += orbitSpeed * delta / (2 * PI * orbitRadius)
	UpdateStatsFromBuildings(delta)
	pass

func UpdateStatsFromBuildings(delta):
	var statsToAdd = {
		"fuel": 0,
		"energy": 0,
		"ore": 0,
		"gold": 0,
		"research": 0
	}
	# sort into generators and exchangers
	var generators = []
	var exchangers = []
	var refiners = []
	for b in buildings:
		if b["type"] == "generator":
			generators.append(b["resource"])
		elif b["type"] == "refiner":
			refiners.append(b["resource"])
		elif b["type"] == "exchanger":
			exchangers.append([b['resourceGain'], b['resourceLose']])
	# deal with generators, refiners, then exchangers
	for g in generators:
		if g in refiners: # more stats
			statsToAdd[g] += delta * planetStats[g] / 100.0 * 2
		else:
			statsToAdd[g] += delta * planetStats[g] / 100.0
	for e in exchangers:
		var exchanged = min(statsToAdd[e[1]], 1.0)
		statsToAdd[e[0]] += exchanged
		statsToAdd[e[1]] -= exchanged
	for key in statsToAdd.keys():
		PlayerStats.stats[key] += statsToAdd[key]

func GenerateStats():
	# randomize seed
	randomize()
	# classification
	var random = randf()
	if random < 0.25:
		classification = 1 # "barren"
	elif random < 0.5:
		classification = 2 # "abundant"
	elif random < 0.75:
		classification = 3 # "bountiful"
	else:
		classification = 4 # "superabundant"
	# actual stats
	var largerStatsNum = randi_range(2, 3)
	if classification >= 2:
		largerStatsNum = randi_range(2, 4)
	if classification == 4:
		largerStatsNum = randi_range(3, 4)
	var keysList = planetStats.keys()
	# shuffle the list and then use to randomly assign stats
	keysList.shuffle()
	for i in range(len(keysList)):
		if i < largerStatsNum:
			planetStats[keysList[i]] = 50+50*(randf()**2)
		else:
			planetStats[keysList[i]]=50*(randf()**2)

func GenerateMesh():
	# Initialize the ArrayMesh.
	var arrayMesh = ArrayMesh.new()
	var surfaceArrayMesh = GeneratePlanetMesh()

	# Create the Mesh. No blendshapes, lods or compression used. Primitive triangles used but other formats exist.
	arrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surfaceArrayMesh)
	
	# set material. Each surface is mesh with a new material
	var surfaceIndex = arrayMesh.get_surface_count() - 1 # not necessary with one material but good to have
	# set the arraymesh so far with this surface material
	arrayMesh.surface_set_material(surfaceIndex, shaderMaterialExport)
	
	# surface tool (normals)
	var surfaceTool = SurfaceTool.new()
	
	surfaceTool.create_from(arrayMesh, 0)
	surfaceTool.generate_normals()
	
	# change the meshinstance to this surface
	var planetMesh = $planetMesh
	planetMesh.mesh = surfaceTool.commit()
	
	# set shader uniforms
	var mat: GeometryInstance3D = planetMesh
	# randomise colours (each line based on different planet)
	var coloursList = [
		Color("#595656"), Color("#BFBEBD"), Color("#8C8888"), Color("#F2F2F2"), Color("#0D0D0D"),
		Color("#88898C"), Color("#D9B391"), Color("#F2DAC4"), Color("#404040"), Color("#0D0D0D"),
		Color("#F2CD88"), Color("#D9B779"), Color("#736A5A"), Color("#BFA27E"), Color("#0D0D0D"),
		Color("#D9BD9C"), Color("#8C5C4A"), Color("F27A5E"), Color("#BF6C5A"), Color("#0D0D0D"),
	]
	var rng = RandomNumberGenerator.new()
	rng.randomize() # randomize with random seed
	# set colours
	mat.set_instance_shader_parameter("baseColor", coloursList[rng.randi_range(0, len(coloursList)-1)])
	mat.set_instance_shader_parameter("nearWaterColor", coloursList[rng.randi_range(0, len(coloursList)-1)])
	mat.set_instance_shader_parameter("slopeColor", coloursList[rng.randi_range(0, len(coloursList)-1)])
	mat.set_instance_shader_parameter("sandHeight", radius+rng.randf_range(-0.5, 0.2))
	# generate collision
	$staticBody/collisionMesh.shape = planetMesh.mesh.create_trimesh_shape()
	
	


func GeneratePlanetMesh():
	var surfaceArrays = []
	surfaceArrays.resize(Mesh.ARRAY_MAX)
	
	var baseVertices = GenerateIcosphereVertices()
	var baseIndices = GenerateIcosphereIndices()
	var vertsAndIndices = IncreaseDetail(IncreaseDetail(IncreaseDetail([baseVertices, baseIndices])))
	
	var displacedVertices = DisplaceTerrain(vertsAndIndices[0])
	
	surfaceArrays[Mesh.ARRAY_VERTEX] = displacedVertices
	surfaceArrays[Mesh.ARRAY_INDEX] = vertsAndIndices[1]
	
	return surfaceArrays

func IncreaseDetail(vertIndexList): # increases the detail
	# for each tri, add new points in middle of each edge & make 4 triangles
	var vertices = vertIndexList[0]
	var indices = vertIndexList[1]
	var newIndices = PackedInt32Array()
	for i in range(len(indices)/3): 
		var start = len(vertices)
		var verts = [vertices[indices[i*3]], vertices[indices[i*3+1]], vertices[indices[i*3+2]]]
		var edgeMidpoints = PackedVector3Array([(verts[0]+verts[1]).normalized(), (verts[1]+verts[2]).normalized(), (verts[0]+verts[2]).normalized()])
		vertices += edgeMidpoints
		newIndices += PackedInt32Array([start, start+1, start+2,
										indices[i*3+1], start+1, start,
										start, start+2, indices[i*3],
										indices[i*3+2], start+2, start+1])
	return [vertices, newIndices]

func DisplaceTerrain(vertices):
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX # kind of like fractal noise
	# simplex noise settings. TD: randomize
	noise.seed = randi()
	noise.fractal_octaves = randi_range(2, 4) # layers of perlin noise
	noise.frequency = 0.5 # initial freq
	noise.fractal_lacunarity = 2 # frequency multiplied by this each new octave
	noise.fractal_gain = 0.5 # amplitude decrease by this each time
	
	radius = randf_range(3, 6)
	var noiseVariation = randf_range(1.5, 3)
	
	for i in range(len(vertices)):
		vertices[i] = vertices[i].normalized()
		vertices[i] += vertices[i] * (radius+noise.get_noise_3dv(vertices[i])*noiseVariation)
	
	# set water height
	$water.mesh.radius = radius
	$water.mesh.height = 2 * (radius-0.2) # in reality, planets are actually slightly oval
	
	# set gravity radius and gravity power
	$gravityVolume/CollisionShape3D.shape.radius = radius * 2 + 2 # randomise
	$gravityVolume.gravity_point_unit_distance = radius # surface gravity
	$gravityVolume.gravity = randf_range(8, 15)
	
	return vertices


# returns a list of arrays
func GenerateIcosphereVertices():
#	var uvs = PackedVector2Array()
#	var normals = PackedVector3Array()
#
	var halfGRatio = (1+sqrt(5))/4 # half golden ratio

	# vertices (see https://en.wikipedia.org/wiki/Regular_icosahedron#Construction)
	var verts = PackedVector3Array([
		Vector3(-0.5, 0, -halfGRatio),
		Vector3(-halfGRatio, -0.5, 0),
		Vector3(0, -halfGRatio, -0.5),
		Vector3(0.5, 0, -halfGRatio),
		
		Vector3(-halfGRatio, 0.5, 0),
		Vector3(0, -halfGRatio, 0.5),
		Vector3(0.5, 0, halfGRatio),
		Vector3(halfGRatio, 0.5, 0),
		
		Vector3(0, halfGRatio, 0.5),
		Vector3(-0.5, 0, halfGRatio),
		Vector3(halfGRatio, -0.5, 0),
		Vector3(0, halfGRatio, -0.5),
	])
	return verts

func GenerateIcosphereIndices():
	var indices = PackedInt32Array([
		0, 11, 4,
		0, 4, 1,
		0, 1, 2,
		0, 2, 3,
		0, 3, 11,

		1, 4, 9,
		6, 7, 10,
		3, 7, 11,
		3, 10, 7,
		3, 2, 10,

		5, 9, 6,
		5, 6, 10,
		5, 10, 2,
		5, 2, 1,
		5, 1, 9,

		8, 6, 9,
		8, 7, 6,
		8, 11, 7,
		8, 4, 11,
		8, 9, 4
	])
	
	return indices
	

