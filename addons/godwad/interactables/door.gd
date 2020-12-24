extends Area

var normal
var active = false
var myFloor = null
var scaleFactor = 1
var targetLines = null
var doorComponents = []
var map
var linedeftype = -1
var tag  = ""


func _ready():
	
	
	var linedeftype = get_meta("linedeftype")
	if(get_parent().get_class() == "StaticBody"):
		tag = get_parent().get_child(1).get_meta("tag")
	else:
		tag = get_parent().get_meta("tag")
	
	
	map = get_parent().get_parent().get_parent().get_parent()

	scaleFactor = map.scaleFactor
	var targets = []
	
	
	var tagSectorsNum = map.getSectorsFromTag(get_parent(),tag)
	
	#if tag!= 0: 
	#	tagSectorsNum = map.get_meta("tagToSectorsDict")[tag]
	#else:
	#	var sides = map.get_meta("allSideDefs")
	#	var oSide = map.getChildMesh(get_parent()).get_meta("oSide")
	#	var targetSide = sides[oSide]
	#	
	#	tagSectorsNum = [targetSide["sector"]]

	for i in tagSectorsNum:
		var sec = map.getSector(i)
		var targetSides = map.getNeighbourSides(sec)#map.getAllSectorSides(sec)
		var fAndC = map.getSectorFloorAndCeil(sec)
		var mids = []
		for j in targetSides:
			if j.name.find("low") == -1:
				mids.append(j)
				
		targets.append({"sector":sec,"sides":mids,"floor":fAndC["floor"],"ceil":fAndC["ceil"] })
	
	
	self.connect("body_entered",self,"body_entered")
	
	
	if targets.empty():
		return 


	for i in targets:
		if i["sector"].get_node_or_null("doorComponent")!= null:
			doorComponents.append( i["sector"].get_node("doorComponent"))
			continue
		var doorComponent = Spatial.new()
		doorComponent.set_script(load("res://addons/godwad/interactables/doorComponent2.gd"))
		doorComponent.walls = i["sides"]
		doorComponent.theFloor = i["floor"]
		doorComponent.theCeil = i["ceil"]
		doorComponent.name = "doorComponent"
		doorComponents.append(doorComponent)
		doorComponent.scaleFactor = scaleFactor
		doorComponent.nieghbourSectors = map.getNeighbourSectors( i["sector"])
		doorComponent.internalWalls = map.getAllEmptySidesOfSector(i["sector"].name)
		doorComponent.map = map
		doorComponent.linedeftype = linedeftype
		i["sector"].add_child(doorComponent)
	
	
	

func body_entered(body):
	if body.get_class() != "StaticBody":
		for i in doorComponents:
			if i != null:
				i.active = true
				print("hit door")

