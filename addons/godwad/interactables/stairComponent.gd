extends Node

var active = false
var line
var mFloor = 0

var scaleFactor = 0

var normal = null
var direction = -1
var moveCeil = false
var map = null
var nieghbourSectors = null
onready var gParent = get_parent().get_parent()
onready var initialPos = gParent.translation
var sectorChain = []
var walls = null
var theFloor = null
var theCeil = null
var linedeftype = 0
var targetY : float = 0.0
var increment = 0
var targetFloors = []
func _ready():
	#diemensions = get_parent().get_meta("dimensions")
	#var line = get_parent().get_meta("line")
	normal =  get_parent().get_meta("normal")
	mFloor  = get_parent().get_meta("floor")
	

		
	match linedeftype:
		7,8,256,258: increment = 8*scaleFactor
		100,127,257,259: increment = 16*scaleFactor

	
	for sector in sectorChain:
		var sectorChildren = sector["sector"].get_children()
		var meta = sector["emptyMeta"]
		for c in sectorChildren:
			if c.has_meta("floor"):
				print(c.get_parent().name)
				
				
				var textureName = meta["textures"]["low"]
				#if textureName == "-":
				#	continue
				targetFloors.append({"node":c,"initialY":c.translation.y})
				var texture = map.levelInstancer.getTexture(textureName)
				var floorZ = meta["floorZ"]
				var lVert = meta["startVert"]
				var rVert = meta["endVert"]
				var light = meta["light"]
				var endZ = increment*targetFloors.size()/scaleFactor
				var wallNode = map.levelInstancer.createWall(lVert/scaleFactor,rVert/scaleFactor,floorZ,floorZ+endZ,0,Vector2.ZERO,true,texture,null,"",0,light)#texture,fCeil,"mid",type,sectorLight)
				var test = wallNode["node"]
				test.translation.y -= (floorZ+endZ)*scaleFactor
				c.add_child(wallNode["node"])

func _process(delta):
	var num = 1
	if active:
		for i in targetFloors:
			var mesh = i["node"]
			if mesh.translation.y < (i["initialY"]+(increment*num)):
				mesh.translation.y+=scaleFactor*0.25
			num+=1 



