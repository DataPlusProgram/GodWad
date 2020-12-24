extends Area

var open = false

enum TRIGGERS{
	WALK_OVER_ONCE,
	WALK_OVER_REPEATABLE,
	SWITCH_ONCE,
	SWITCH_REPEATABLE,
	GUNFIRE_ONCE,
	GUNFIRE_REPEATABLE,
	DOOR_ONCE,
	DOOR_REPEATABLE
}

enum ACTIONS{
	OPEN_WAIT_CLOSE,
	OPEN,
	CLOSE_WAIT_OPEN,
	CLOSE
}

enum SPEED{
	SLOW,
	NORMAL,
	TURBO
}

enum WAIT{
	ONE_SECOND,
	FOUR_SECONDS,
	NINE_SECONDS,
	THIRTY_SECONDS
}

var tag = ""
var trigger
var action
var wait 
var monsters
var keyName = ""
var targetDoor

var targetDisplacement = Vector3.ZERO
var speed = Vector3(0,-200,0)
var initialPos = Vector3.ZERO
var ceilDiff = null
var doorComponents = []

func _ready():
	initialPos = get_parent().translation
	self.connect("body_entered",self,"body_entered")
	var tag = get_parent().get_child(1).get_meta("tag")
	if tag == null:
		return
		
	var allSidesOfTag = getAllLinesOfTag(tag)
	if allSidesOfTag ==  null:
		return

	var allReleventSides = []
	for side in allSidesOfTag:
		if side.has_meta("isTwoSided"):
			if side.get_meta("isTwoSided") == true:
				allReleventSides.append(side)
	
	
	for i in allReleventSides:
		if i!= null:
			
			var targetMesh = i.get_parent().get_child(1)
			
			if i.get_class() == "MeshInstance":
				targetMesh = i
			
			var line = targetMesh.get_meta("line")
			#if line == null:
			#	print("door error")
			#	return
			var normal =  targetMesh.get_meta("normal")
			var scaleFactor =targetMesh.get_meta("scaleFactor")
			var diemnsion = targetMesh.get_meta("dimensions")
	
		
			var ray = RayCast.new()
			ray.cast_to = Vector3.ZERO
			ray.cast_to.z = normal.x*100
			ray.cast_to.x = -normal.y*100
			
			ray.translation.x = -(line*0.5).x*scaleFactor
			ray.translation.z =-(line*0.5).y*scaleFactor
			ray.translation.y = -diemnsion.y*0.9
			ray.enabled = true
			ray.set_script(load("res://addons/godwad/interactables/doorRay.gd"))
			
			var doorCi
			var doorComponent =Spatial.new()
			doorComponent.set_script(load("res://addons/godwad/interactables/doorComponent.gd"))
			doorComponent.name = "DoorComponent"
			doorComponents.append(doorComponent)
			i.add_child(doorComponent)
			if ray!= null:
				doorComponent.add_child(ray)
	#	var bloop =  ((get_tree().get_nodes_in_group("sector_tag_" + String(tag))))

	
	


func body_entered(body):
	if body.get_class() != "StaticBody":
		open(body)
		#open = true
		for i in doorComponents:
			if i != null:
				i.open = true
		


func open(body):
	if keyName!= "" and body.has_meta("key"):
		if body.get_meta("key") != keyName:
			return

func getAllLinesOfTag(tag):
	var tagStr = String(tag)
	if tag == 0:
		return [get_parent().get_child(1)]
	
	var targetSectors = null
	var map = get_parent().get_parent().get_parent()
	
	targetSectors = get_tree().get_nodes_in_group("sector_tag_" + String(tag))#we get the sectors that have the tag
	
	var sides=[]
	if targetSectors.empty():#no sectors have the tag so abandon
		return [get_parent().get_child(1)]
		
	var allSides = []
	for sector in targetSectors:
		var sectorSides = getSectorSides(sector)
		if sectorSides != null:
			allSides += sectorSides
			
	if allSides.empty():
		return null
	#this is the filter part of the function which will need to be broken off into its own function at some stage
	return allSides

func getSectorSides(sector):#get all sides relevent to sector
	var sides = []
	
	for child in sector.get_children():#get sides that are facing the sector
		if child.get_class() == "StaticBody":
			var lineMeshOrNull = getLineMesh(child)
			if lineMeshOrNull != null:
				sides.append(lineMeshOrNull)
				
				
	var nieghbourSidedefs = get_tree().get_nodes_in_group("neighbourSector" + sector.get_name())#get sides that face away from sector but share a line with it
	

	return sides + nieghbourSidedefs
	
func getLineMesh(line):#for a given line StaticBody get its linedef MeshInstance Node
	for i in line.get_children():
		if i.has_meta("floor"):
			return i
	return null

