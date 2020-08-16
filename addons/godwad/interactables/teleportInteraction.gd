extends Area
var destination = global_transform.origin
var tag = ""
onready var map = get_parent().get_parent().get_parent().get_parent()

func _ready():
	
	if(get_parent().get_class() == "StaticBody"):
		tag = get_parent().get_child(1).get_meta("tag")
	else:
		tag = get_parent().get_meta("tag")
	
	self.connect("body_entered",self,"body_entered")
	if tag!= 0:# and tag!=null:
		findTeleportThing(tag)


func body_entered(body):
	#print("tag" + String(tag))
	if body.get_class() != "StaticBody":
		print("body entered")
		var yOffset = 0
		if body.has_meta("height"):
			yOffset = body.get_meta("height")
			
		body.translation = destination + Vector3(0,yOffset,0)
	

func findTeleportThing(tag):
	#if tag == 55:
	#	breakpoint 
	#print("thing_in_sector_" + String(tag))
	var grpStr  = "thing_in_tag_sector_" + String(tag)
	
	var result = get_tree().get_nodes_in_group(grpStr)
	
	
	for i in result:
		destination = i.translation#if there are multiple destinations the last one will be used
	#	var sec = map.getSector(i.get_meta("sector"))
	#	var floorH = sec.get_meta("floorHeight")
	#	var ceilH = sec.get_meta("ceilingHeight")
	#	var mid = (ceilH - floorH)*0.5
		#destination.y = mid*map.scaleFactor
	
	
	#print(destination)

