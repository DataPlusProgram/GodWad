extends Area

var mFloor
var normal
var active = false
var myFloor = null
var scaleFactor = 1
var targetLines = null
var stairComponents = []
var myNormal = null
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
	
	
	var tagSectorsNum
	if tag == null:
		return
	
	if tag!= 0:
		var targetSector = map.get_meta("tagToSectorsDict")[tag]
		var emptySides = map.getAllEmptySidesOfSector(targetSector[0])
		var emptyMeta = "-"
		for e in emptySides:
			if e["normal"] == myNormal:
				emptyMeta = e
				tagSectorsNum = [{"sector":targetSector[0],"emptyMeta":emptyMeta}]
	else:
		var sides = map.get_meta("allSideDefs")
		var oSide = map.getChildMesh(get_parent()).get_meta("oSide")
		var targetSide = sides[oSide]
		
		var neighBourLine = (get_tree().get_nodes_in_group("neighbourSector1")[0].name)
		var sector= (targetSide["sector"])
		tagSectorsNum = [{"sector":sector,"emptyMeta":targetSide}]
		#tagSectorsNum = [{"sector":targetSide["sector"],"texture":targetSide}]

	if tagSectorsNum == null:
		return
		
	for i in tagSectorsNum:
		var sec = map.getSector(i["sector"])
		var fAndC = map.getSectorFloorAndCeil(sec)
		var stairChain = stairBuild([{"sector":sec,"emptyMeta":i["emptyMeta"]}])
		if stairChain == null:
			return
		#targets.append({"sector":sec,"sides":[],"floor":fAndC["floor"],"ceil":fAndC["ceil"] })
		targets.append(stairChain)
	self.connect("body_entered",self,"body_entered")
	
	
	if targets.empty():
		return 
	
	
	
	var stairComponent = Spatial.new()
	for i in targets:
		#if i["sector"].get_node_or_null("stairComponent")!= null:
		#	stairComponents.append( i["sector"].get_node("stairComponent"))
		#	continue
		
		stairComponent.set_script(load("res://addons/godwad/interactables/stairComponent.gd"))
		stairComponent.sectorChain = i
		#stairComponent.walls = i["sides"]
		#stairComponent.theFloor = i["floor"]
		#stairComponent.theCeil = i["ceil"]
		#stairComponent.name = "stairComponent"
		stairComponents.append(stairComponent)
		stairComponent.scaleFactor = scaleFactor
		#stairComponent.nieghbourSectors = map.getNeighbourSectors( i["sector"])
		stairComponent.map = map
		stairComponent.linedeftype = linedeftype
		i[0]["sector"].add_child(stairComponent)
	
	

func body_entered(body):
	if body.get_class() != "StaticBody":
		for i in stairComponents:
			if i != null:
				i.active = true
				print("hit stair")

func stairBuild(secTextTuple):
	var curSec = secTextTuple.back()["sector"]
	#var parNormal = get_parent().get_meta("normal")
	var parNormal = myNormal
	var targetSides = map.getLocalSides(curSec)
	var emptySides = map.getAllEmptySidesOfSector(curSec.name)
	var nextsec = null
	
	for e in emptySides:
		if e["normal"] == parNormal:
			var targetSector = map.getSector(e["neighbourSector"])
			var emptyMeta = e
			secTextTuple.append({"sector":targetSector,"emptyMeta":emptyMeta})
			secTextTuple = stairBuild(secTextTuple)

	
	#for j in targetSides:
	#	print(j.get_meta("oSide"))
	#	print("----")
	#	if (j.get_meta("normal")) == parNormal:
	#		sec.append(map.getSector(j["neighbourSector"]))
	#		sec = stairBuild(sec)
	#		breakpoint
	return secTextTuple
	
