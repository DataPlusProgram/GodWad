extends Node

var active = false
var line

var scaleFactor = 0

var direction = -1
var moveCeil = false
var map = null
var nieghbourSectors = null
onready var gParent = get_parent().get_parent()
onready var initialPos = gParent.translation
var timer = null
var walls = null
var theFloor = null
var theCeil = null
var linedeftype = 0
var endY : float = -1000
var startY = 0
var startPosDict = {}
var gapsFilled = false
func _ready():

	
	if theFloor != null:
		startY = theFloor.translation.y
		
	
	match linedeftype:
		5,24,64,91,101: endY = map.getLowestNeighbourCeil(get_parent())*scaleFactor
		36,70,71,98: endY = (map.getHighestNeighbourFloor(get_parent(),false)+8)*scaleFactor#heretic works different
		55,56,65,94: endY = (map.getLowestNeighbourCeil(get_parent())-8)*scaleFactor
		15,58,59,66,92,93,160,161,179,180: endY = startY + (24*scaleFactor)#wrong
		140,142,147,148: endY = (512*scaleFactor)#wrong
		23,37,38,60,82,84,159,177: endY = map.getLowestNeighbourFloor(get_parent())*scaleFactor
		19,45,83,102: endY = map.getHighestNeighbourFloor(get_parent())*scaleFactor
		18,20,69,119,128,129,130,131,132,219,220,221,222: endY = map.raiseNextNeighbourFloor(get_parent())*scaleFactor
		
	match linedeftype:
		70: direction = -1
		18,64,20: direction = 1
		15,5,24,64,91,101: direction = 1
	
	
	for i in walls:
		var iParent = i.get_parent()
		if i.get_parent().get_class() != "StaticBody":
			iParent = self
			
	

	#extendFloor(endY,startY)
	

func _process(delta):
	
	if gapsFilled == false:
		fillInGaps2(walls,endY,theFloor.translation.y)
		gapsFilled = true

	if active:
		
		var canMoveDown = canMoveDown(theFloor)
		var canMoveUp = canMoveUp(theFloor)
		
		if canMoveDown and direction == -1:
			theFloor.translation.y += -1*scaleFactor
			for i in walls:
				if i.name.find("top") == -1:
					move(i,-1)
		
		if canMoveUp and direction == 1:
			theFloor.translation.y += 1*scaleFactor
			for i in walls:
				if i.name.find("top") == -1:
					move(i,1)
		
		if !canMoveDown and direction == -1:
			direction = 0
			arriveBottom()
			
		
		if !canMoveUp and direction == 1:
			direction = 0
			arriveTop()
			
		
			

func arriveBottom():
	match linedeftype:
		66,67,68,181,182,62,123,148,149,95,87,88,89,120,212: startTimer(1)
		
	
	

func arriveTop():
	active = false
	
	pass
	
func move(node,dir):
	var iParent = node.get_parent()
	if node.get_parent().get_class() != "StaticBody":
		iParent = node
	if "translation" in iParent:
		iParent.translation.y += dir*scaleFactor
		

func time():
	direction =1
	timer.queue_free()
	timer = null



func startTimer(dur):
	timer = Timer.new()
	timer.set_wait_time(1)
	timer.one_shot = false
	timer.connect("timeout",self,"time")
				
	add_child(timer)
	timer.start()

func canMoveUp(node):
	var top = endY
	var iParent = node.get_parent()
	if node.get_parent().get_class() != "StaticBody":
		iParent = node
	
	var parY = iParent.global_transform.origin.y
	return  parY  < top
	
func canMoveDown(node):
	var iParent = node.get_parent()
	if node.get_parent().get_class() != "StaticBody":
		iParent = node
		
	var parY = iParent.global_transform.origin.y
	return  parY  > endY
	

func extendFloor(end,floorY):
	var sector = get_parent().get_parent()
	var targets = []
	
	if get_parent().get_class() == "Spatial":
		sector = get_parent()
		pass
		
	targets =get_tree().get_nodes_in_group("neighbourSector" + sector.get_name())
	if targets.empty():
		var emptyLines = map.get_meta("emptySides")
		for i in emptyLines.values():
			if i.has("neighbourSector"):
				if i["neighbourSector"] == int(sector.name):
					if i["textures"]["low"] != '-': createResized(i,end,sector,i["textures"]["low"])
					elif i["textures"]["mid"] != '-': createResized(i,end,sector,i["textures"]["mid"])
					elif i["textures"]["high"] != '-': createResized(i,end,sector,i["textures"]["high"])
						
				#targets.append(i)
				
	
	if !targets.empty():
		for cur in targets:
			var sideDefs = map.get_meta("allSideDefs")
			for i in targets:
				if i.get_meta("sidedefIndex") == null:
					continue
				var sideData = sideDefs[i.get_meta("sidedefIndex")]
				if sideData.has("low"):
					createResized(sideData["low"],end,sector,sideData["textures"]["low"])
				
	
func createResized(f,end,sector,textureName):
	
		if textureName == "-":
			return
		
		var texture = map.levelInstancer.getTexture(textureName)
		var start = f["floorZ"]
		var lVert = f["startVert"]/scaleFactor
		var rVert = f["endVert"]/scaleFactor
		var light = f["light"]
		
		var newWall = map.levelInstancer.createWall(rVert,lVert,end/scaleFactor,start/scaleFactor,0,Vector2.ZERO,true,texture,null,"",0,light)
		var nodeCol = newWall["meta"]["meshNode"].get_parent()
		theFloor.add_child(newWall["node"])
		#sector.add_child(newWall["node"])
		#walls.append(nodeCol)
		nodeCol.translation.y =  (start-end)
		

func reparent(child, newParent):
	var oldParent = child.get_parent()
	oldParent.remove_child(child)
	newParent.add_child(child)

func fillInGaps2(sides,end,floorY):
	
	var targets = []
	var sector = get_parent().get_parent()
	if get_parent().get_class() == "Spatial":
		sector = get_parent()
	
	var emptySides = map.getAllEmptySidesOfSector(int(sector.name))
	if !emptySides.empty():
		for cur in emptySides:
			if cur["textures"]["low"] != '-':
				var textureName = cur["textures"]["low"]
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
			map.rewall(side,"mid",i,end,sector)
	
		elif side.has("low"):
			map.rewall(side,"low",i,end,sector)
