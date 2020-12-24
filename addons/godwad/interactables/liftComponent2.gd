extends Node

var active = false
var line

var scaleFactor = 0
var startY = 0
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
var targetY : float = -1000
var startPosDict = {}
var gapsFilled = false
func _ready():
	

	
	if theFloor != null:
		 startY = theFloor.translation.y
	
	match linedeftype:
		15,45,148,143: targetY =   + (24*scaleFactor)
		14,67,144,149: targetY = startY + (32*scaleFactor)
		10,21,62,88,120,121,122,123: targetY = map.getLowestNeighbourFloor(get_parent())*scaleFactor
		211,222: targetY = get_parent().get_meta("ceiling")
		20,22,47,68,95: targetY = map.raiseNextNeighbourFloor(get_parent())*scaleFactor
		
	match linedeftype:
		14,15,20,22,48,66,68,95,1430,144,148,149: direction = 1
	

	

func _process(delta):

	if active:
		if gapsFilled==false:
			fillInGaps2(walls,targetY,startY)
			gapsFilled = true
		
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
	print("hit bottom")
	#if theFloor.translation.y < targetY:
	#	theFloor.translation.y = targetY
	
	match linedeftype:
		66,67,68,181,182,62,123,148,149,95,87,88,89,120,212: 
			startTimer(1)
		
	
	

func arriveTop():
	active = false

	
func move(node,dir):
	var iParent = node.get_parent()
	if node.get_parent().get_class() != "StaticBody":
		iParent = node
	iParent.translation.y += dir*scaleFactor
		

func time():
	direction =1
	active = true
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
	var top = startY
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
	return  parY > targetY 
	
	
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
				
		
				var lVert = cur["startVert"]/scaleFactor
				var rVert = cur["endVert"]/scaleFactor
				var light = cur["light"]
				var wall = map.levelInstancer.createWall(lVert,rVert,end/scaleFactor,start/scaleFactor,0,Vector2.ZERO,true,texture,null,"",0,light)#texture,fCeil,"mid",type,sectorLight)
				sector.add_child(wall["node"])
	
	for child in sector.get_children():#get sides that are facing the sector
		if child.get_class() == "StaticBody":
			var lineMeshOrNull = map.getLineMesh(child)
			if lineMeshOrNull != null:
				targets.append(lineMeshOrNull)
#	#	
	
	var sideDefs = map.get_meta("allSideDefs")
	
	for i in targets:
		var sideMeta =  map.get_meta("allSideDefs")[i.get_meta("sidedefIndex")]
		var textures =sideMeta["textures"]
		var side = sideDefs[i.get_meta("sidedefIndex")]
		#if(i.name == "linedef 124 top"):
		#	breakpoint
		if side.has("mid") and !side.has("low"):
			map.rewall(side,"mid",i,end,sector)

		#elif side.has("high") and textures["mid"]== "-" and textures["low"]!= "-":
		elif side.has("high") and !side.has("mid") and textures["low"]!= "-":
			var osideIndex = side["high"]["meshNode"].get_meta("oSide")
			if osideIndex != 65535:
				var oside = map.get_meta("allSideDefs")[osideIndex]#lots of hacky conditions
				if oside["textures"]["low"] == "-":
					var high = side["high"]["floorZ"]
					var f = side["floorZ"]
					print(textures)
					map.rewall(side,"high",i,end,sector,false,0)
		
		elif side.has("low"):
			map.rewall(side,"low",i,end,sector)
