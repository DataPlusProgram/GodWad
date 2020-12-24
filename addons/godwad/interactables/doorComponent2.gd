extends Spatial

var open = false

var walls
var theFloor
var theCeil
var scaleFactor
var nieghbourSectors 
var map
var linedeftype
var active 
var endY
var internalWalls
var gapsFilled = false

func _ready():
	endY =  map.getLowestNeighbourCeil(get_parent(),false)*scaleFactor

	
	
	#self.connect("body_entered",self,"body_entered")
	
func fillInGaps2(end,floorY):
	
	var targets = []
	var sector = get_parent().get_parent()
	if get_parent().get_class() == "Spatial":
		sector = get_parent()
	
	var emptySides = []
	if !emptySides.empty():
		for cur in emptySides:
			
			if cur["textures"]["mid"] != '-':
				var textureName = cur["textures"]["mid"]
				var texture = map.levelInstancer.getTexture(textureName)
				var start = cur["floorZ"] * scaleFactor
				var lVert = cur["startVert"]
				var rVert = cur["endVert"]
				var light = cur["light"]

				map.levelInstancer.createWall(lVert,rVert,end/scaleFactor,start/scaleFactor,0,Vector2.ZERO,true,texture,null,"",0,light)#texture,fCeil,"mid",type,sectorLight)
				

	for child in sector.get_children():#get sides that are facing the sector
		if child.get_class() == "StaticBody":
			
			var lineMeshOrNull = map.getLineMesh(child)
			if lineMeshOrNull != null:
				targets.append(lineMeshOrNull)
#	#	
	
	var sideDefs = map.get_meta("allSideDefs")
	for i in targets:
		var side = sideDefs[i.get_meta("sidedefIndex")]
		if side.has("mid") and !side.has("low"):
			map.rewall(side,"mid",i,end,sector,true)


func _physics_process(delta):
	if gapsFilled == false:
		fillInGaps2(endY,theFloor.translation.y)
		gapsFilled = true
	
	
	if active == true:
		if theCeil.translation.y < endY:
			for i in walls:
				var iParent = i.get_parent()
				if i.get_parent().get_class() != "StaticBody":
					iParent = self
			
				iParent.translation.y += 1 * scaleFactor
			theCeil.translation.y += 1 * scaleFactor
