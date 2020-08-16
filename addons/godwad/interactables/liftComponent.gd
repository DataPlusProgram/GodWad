extends Node

var active = false
var line
var mFloor = 0

var scaleFactor = 0
var myFloor = null
var liftCeil = null
var normal = null
var direction = -1
var moveCeil = false
var map = null
onready var gParent = get_parent().get_parent()
onready var initialPos = gParent.translation
var sidesToMove = []
var sidesNoFilter = []
var sideSectorNode = null
var checked = false
var gapsFilled = false
# Called when the node enters the scene tree for the first time.
func _ready():

	var line = get_parent().get_meta("line")
	normal =  get_parent().get_meta("normal")
	scaleFactor = get_parent().get_meta("scaleFactor")
	var diemnsions = get_parent().get_meta("dimensions")
	mFloor  = get_parent().get_meta("floor")
	


func _process(delta):
	
	if checked == false:
		sidesNoFilter =getSidesToMove()
		
		if sidesNoFilter == null:
			checked = true
			return
		
		for i in sidesNoFilter:
			if i.name.find("low") != -1:
				sidesToMove.append(i)
		
		for c in sideSectorNode.get_children():
			if c.has_meta("floor"):
				if c.name.find("linedef") == -1:#a hack because I doubled up on the floor metatag
					myFloor = c
					
			if c.has_meta("ceil"):
				liftCeil = c
		
		#fillInGaps(sidesToMove)
		checked = true
		
		
	
	if active:
		if gapsFilled == false:
			fillInGaps(sidesNoFilter)
			gapsFilled = true
			
		var isGoingDown = direction ==-1 and (gParent.translation.y) > mFloor*scaleFactor
		var isGoingUp = direction == 1  and (gParent.translation.y) <= initialPos.y
		
		#if  (gParent.translation.y) <= mFloor*scaleFactor: 
		#	direction = 1
		#	isGoingUp = 1
		
		if isGoingDown or isGoingUp:
			if sidesToMove != null:
				for i in sidesToMove:
					if i == null:
						continue
					i.get_parent().translation.y+= 0.025*direction
			
			
			if myFloor != null:
				myFloor.translation.y += 0.025 * direction
			
			if liftCeil != null and moveCeil:
				liftCeil.translation.y += 0.025 * direction
				
		if sideSectorNode == null:
			return
		

func getSidesToMove():
	var oSide  =get_parent().get_meta("oSide")
	var oSideLineInfo = (map.allSideDefs[oSide])
	var oSideSectorStr = String(oSideLineInfo["sector"])
		
	
	
	if(get_parent().get_parent().get_class() == "StaticBody"):
		sideSectorNode = gParent.get_parent().get_parent().get_node(oSideSectorStr)
	else:
		sideSectorNode = gParent.get_parent().get_node(oSideSectorStr)
	
	var sides = null
	
	if sideSectorNode != null:
		sides = map.getSectorSides(sideSectorNode)
	
	return sides
	

func fillInGaps(sides):
	if sides == null:
		return
		
	for i in sides:
		if i == null:
			continue
		if i.name.find("mid") != -1:
			if i.has_meta("dimensions"):
				var dim = i.get_meta("dimensions")
				for j in range(1,4):
					var new = i.get_parent().duplicate()
					map.stripScripts(new)
					new.translation.y -= dim.y*j
					i.get_parent().get_parent().add_child(new)
