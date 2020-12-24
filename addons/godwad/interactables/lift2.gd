extends Area

var mFloor
var normal
var active = false
var myFloor = null
var scaleFactor = 1
var targetLines = null
var liftComponents = []
var map
var linedeftype = -1
var tag  = ""



func _ready():
	map = get_parent().get_parent().get_parent().get_parent()
	
	var linedeftype = get_meta("linedeftype")
	if(get_parent().get_class() == "StaticBody"):
		tag = get_parent().get_child(1).get_meta("tag")
	else:
		tag = get_parent().get_meta("tag")
		
	

		
	
	scaleFactor = map.scaleFactor
	var targets = []
	var oTargets = []
	
	var tagSectorsNum = map.getSectorsFromTag(get_parent(),tag)
	
	
	
	#if tag!= 0: 
	#	
	#	tagSectorsNum = map.get_meta("tagToSectorsDict")[tag]
	#	else: tag = 0
	#if tag==0:
	#	var sides = map.get_meta("allSideDefs")
	#	if  map.getChildMesh(get_parent()) == null:#not too sure how this condition works
	#		return
	#	var oSide = map.getChildMesh(get_parent()).get_meta("oSide")
	#	var targetSide = sides[oSide]
	#	var targetSector = targetSide["sector"]
	#	tagSectorsNum = [targetSide["sector"]]

	
	for i in tagSectorsNum:
		var sec = map.getSector(i)
		var targetSides = map.getNeighbourSides(sec)
		var fAndC = map.getSectorFloorAndCeil(sec)

		targets.append({"sector":sec,"sides":targetSides+oTargets,"floor":fAndC["floor"],"ceil":fAndC["ceil"] })
	
	
	self.connect("body_entered",self,"body_entered")
	
	
	if targets.empty():
		return 
	
	
	
	
	for i in targets:
		if i["sector"].get_node_or_null("liftComponent")!= null:
			liftComponents.append( i["sector"].get_node("liftComponent"))
			continue
		var liftComponent = Spatial.new()
		liftComponent.set_script(load("res://addons/godwad/interactables/liftComponent2.gd"))
		var walls = i["sides"]
		liftComponent.walls = i["sides"]
		liftComponent.theFloor = i["floor"]
		liftComponent.theCeil = i["ceil"]
		liftComponent.name = "liftComponent"
		liftComponents.append(liftComponent)
		liftComponent.scaleFactor = scaleFactor
		liftComponent.nieghbourSectors = map.getNeighbourSectors( i["sector"])
		liftComponent.map = map
		liftComponent.linedeftype = linedeftype
		i["sector"].add_child(liftComponent)
	
	

func body_entered(body):
	if body.get_class() != "StaticBody":
		for i in liftComponents:
			if i != null:
				if i.active == false:
					i.active = true
					i.direction = -1
				print("hit lift")

